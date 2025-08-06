#!/bin/bash

# GitOps Platform Setup Script
# This script helps you set up a modern GitOps platform using Crossplane and ArgoCD

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for pods to be ready
wait_for_pods() {
    local namespace=$1
    local label_selector=$2
    local timeout=${3:-300}
    
    print_status "Waiting for pods in namespace '$namespace' with selector '$label_selector' to be ready..."
    kubectl wait --for=condition=ready pod -l "$label_selector" -n "$namespace" --timeout="${timeout}s"
}

# Function to wait for CRDs to be established
wait_for_crd() {
    local crd_name=$1
    local timeout=${2:-300}
    
    print_status "Waiting for CRD '$crd_name' to be established..."
    kubectl wait --for condition=established --timeout="${timeout}s" crd/"$crd_name"
}

# Prerequisites check
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists kubectl; then
        print_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    
    if ! command_exists helm; then
        print_error "helm is not installed. Please install helm first."
        exit 1
    fi
    
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Phase 1: Bootstrap Setup
bootstrap_setup() {
    print_status "Phase 1: Bootstrap Setup"
    
    # Create namespaces
    print_status "Creating bootstrap namespaces..."
    kubectl apply -f bootstrap/namespaces.yaml
    
    print_success "Bootstrap namespaces created!"
}

# Phase 2: Install Crossplane
install_crossplane() {
    print_status "Phase 2: Installing Crossplane"
    
    # Install Crossplane using Helm
    print_status "Installing Crossplane..."
    helm repo add crossplane-stable https://charts.crossplane.io/stable
    helm repo update
    
    helm upgrade --install crossplane crossplane-stable/crossplane \
        --namespace crossplane-system \
        --create-namespace \
        --version 1.14.5 \
        --wait
    
    # Wait for Crossplane pods to be ready
    wait_for_pods "crossplane-system" "app=crossplane" 180
    
    # Install providers
    print_status "Installing Crossplane providers..."
    kubectl apply -f bootstrap/crossplane/provider-installs.yaml
    
    # Wait for providers to be healthy
    print_status "Waiting for providers to be healthy..."
    sleep 30
    kubectl wait --for=condition=Healthy provider.pkg.crossplane.io --all --timeout=300s
    
    print_success "Crossplane installation completed!"
}

# Phase 3: Install ArgoCD
install_argocd() {
    print_status "Phase 3: Installing ArgoCD"
    
    # Install ArgoCD using Helm
    print_status "Installing ArgoCD..."
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    
    helm upgrade --install argocd argo/argo-cd \
        --namespace argocd \
        --create-namespace \
        --version 5.51.6 \
        --values - <<EOF
global:
  domain: argocd.local

configs:
  params:
    server.insecure: true
    application.instanceLabelKey: argocd.argoproj.io/instance

server:
  service:
    type: ClusterIP
  ingress:
    enabled: false
    
dex:
  enabled: false
  
notifications:
  enabled: true
  
applicationSet:
  enabled: true
  
redis-ha:
  enabled: false

controller:
  replicas: 1
  
repoServer:
  replicas: 1
  
server:
  replicas: 1
EOF

    # Wait for ArgoCD pods to be ready
    wait_for_pods "argocd" "app.kubernetes.io/name=argocd-server" 300
    
    print_success "ArgoCD installation completed!"
    
    # Get ArgoCD admin password
    print_status "Getting ArgoCD admin password..."
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    print_success "ArgoCD admin password: $ARGOCD_PASSWORD"
    print_warning "Please save this password and delete the secret: kubectl -n argocd delete secret argocd-initial-admin-secret"
}

# Phase 4: Configure Crossplane Providers
configure_providers() {
    print_status "Phase 4: Configuring Crossplane Providers"
    
    # Apply provider configurations
    print_status "Applying provider configurations..."
    kubectl apply -f infrastructure/crossplane/providers/provider-config/
    
    # Wait for provider configs to be ready
    sleep 10
    
    print_success "Provider configurations applied!"
}

# Phase 5: Deploy Infrastructure Components
deploy_infrastructure() {
    print_status "Phase 5: Deploying Infrastructure Components"
    
    # Apply XRDs
    print_status "Applying XRDs..."
    kubectl apply -f infrastructure/crossplane/xrds/
    
    # Wait for XRDs to be established
    wait_for_crd "xobservabilitystacks.platform.example.com" 60
    wait_for_crd "xingressstacks.platform.example.com" 60
    
    # Apply Compositions
    print_status "Applying Compositions..."
    kubectl apply -f infrastructure/crossplane/compositions/
    
    print_success "Infrastructure components deployed!"
}

# Phase 6: Setup ArgoCD App of Apps
setup_argocd_apps() {
    print_status "Phase 6: Setting up ArgoCD App of Apps"
    
    print_warning "Please update the Git repository URLs in argocd-apps/ files before proceeding."
    read -p "Have you updated the Git repository URLs? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Please update the repository URLs and run this phase again."
        return 1
    fi
    
    # Apply App of Apps
    print_status "Applying App of Apps..."
    kubectl apply -f argocd-apps/app-of-apps.yaml
    
    print_success "ArgoCD App of Apps configured!"
}

# Phase 7: Port-forward ArgoCD UI
port_forward_argocd() {
    print_status "Setting up port-forward for ArgoCD UI..."
    print_status "ArgoCD UI will be available at: http://localhost:8080"
    print_status "Username: admin"
    print_status "Password: $ARGOCD_PASSWORD"
    print_warning "Press Ctrl+C to stop port-forwarding"
    
    kubectl port-forward svc/argocd-server -n argocd 8080:443
}

# Main execution
main() {
    echo "========================================"
    echo "GitOps Platform Setup"
    echo "Crossplane + ArgoCD"
    echo "========================================"
    echo
    
    check_prerequisites
    
    echo
    echo "Setup phases:"
    echo "1. Bootstrap Setup"
    echo "2. Install Crossplane"
    echo "3. Install ArgoCD"
    echo "4. Configure Providers"
    echo "5. Deploy Infrastructure"
    echo "6. Setup ArgoCD Apps"
    echo "7. Port-forward ArgoCD UI"
    echo
    
    read -p "Do you want to run all phases? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        bootstrap_setup
        install_crossplane
        install_argocd
        configure_providers
        deploy_infrastructure
        setup_argocd_apps
        port_forward_argocd
    else
        echo "You can run individual phases by calling the functions directly."
        echo "Available functions:"
        echo "- bootstrap_setup"
        echo "- install_crossplane"
        echo "- install_argocd"
        echo "- configure_providers"
        echo "- deploy_infrastructure"
        echo "- setup_argocd_apps"
        echo "- port_forward_argocd"
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
