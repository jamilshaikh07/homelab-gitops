#!/bin/bash

# Quick setup script for existing Crossplane installation
# Since Crossplane and providers are already installed, we'll start from provider configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if we can connect to cluster
check_cluster_access() {
    print_status "Checking cluster access..."
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        print_warning "For Talos clusters, make sure you have the correct kubeconfig:"
        print_warning "  talosctl kubeconfig -n <node-ip>"
        exit 1
    fi
    print_success "Cluster access verified!"
}

# Phase 4: Configure Crossplane Providers
configure_providers() {
    print_status "Phase 4: Configuring Crossplane Providers"
    
    # Check if providers are healthy
    print_status "Checking provider status..."
    kubectl get providers
    
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
    print_status "Waiting for XRDs to be established..."
    kubectl wait --for condition=established --timeout=60s crd/xobservabilitystacks.platform.example.com
    kubectl wait --for condition=established --timeout=60s crd/xingressstacks.platform.example.com
    
    # Apply Compositions
    print_status "Applying Compositions..."
    kubectl apply -f infrastructure/crossplane/compositions/
    
    print_success "Infrastructure components deployed!"
}

# Phase 6: Deploy Platform Services
deploy_platform_services() {
    print_status "Phase 6: Deploying Platform Services"
    
    print_warning "Before proceeding, please update the following in your configuration files:"
    print_warning "1. NFS server IP in infrastructure/platform/storage/nfs-csi-setup.yaml"
    print_warning "2. Network IP ranges for MetalLB"
    print_warning "3. Domain names for ingress"
    
    read -p "Have you updated the configuration files? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Please update the configuration files and run this script again."
        return 1
    fi
    
    # Deploy storage
    print_status "Deploying NFS CSI driver..."
    kubectl apply -f infrastructure/platform/storage/
    
    # Deploy platform services through claims
    print_status "Deploying platform service claims..."
    kubectl apply -f infrastructure/platform/ingress/
    kubectl apply -f infrastructure/platform/observability/
    kubectl apply -f infrastructure/platform/backup/ 2>/dev/null || print_warning "Backup configuration skipped (update Velero settings first)"
    
    print_success "Platform services deployment initiated!"
}

# Phase 7: Install ArgoCD (if not already installed)
install_argocd() {
    print_status "Phase 7: Checking ArgoCD installation"
    
    if kubectl get namespace argocd >/dev/null 2>&1; then
        print_success "ArgoCD namespace already exists"
        if kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server >/dev/null 2>&1; then
            print_success "ArgoCD is already installed"
            return 0
        fi
    fi
    
    print_status "Installing ArgoCD..."
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    
    # Install ArgoCD
    helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
    helm repo update >/dev/null 2>&1
    
    helm upgrade --install argocd argo/argo-cd \
        --namespace argocd \
        --version 5.51.6 \
        --set configs.params."server\.insecure"=true \
        --set server.service.type=ClusterIP \
        --set dex.enabled=false \
        --wait
    
    print_success "ArgoCD installed successfully!"
    
    # Get ArgoCD password
    print_status "Getting ArgoCD admin password..."
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Password not found")
    print_success "ArgoCD admin password: $ARGOCD_PASSWORD"
}

# Phase 8: Setup GitOps
setup_gitops() {
    print_status "Phase 8: Setting up GitOps with ArgoCD"
    
    print_warning "Before setting up GitOps, you need to:"
    print_warning "1. Push this repository to your Git hosting service (GitHub/GitLab)"
    print_warning "2. Update the repository URLs in argocd-apps/ files"
    
    read -p "Have you updated the Git repository URLs in argocd-apps/? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Please update the repository URLs and run this phase again."
        print_status "Files to update:"
        print_status "  - argocd-apps/app-of-apps.yaml"
        print_status "  - argocd-apps/infrastructure-apps.yaml"  
        print_status "  - argocd-apps/application-apps.yaml"
        return 1
    fi
    
    # Apply App of Apps
    print_status "Applying App of Apps..."
    kubectl apply -f argocd-apps/app-of-apps.yaml
    
    print_success "GitOps setup completed!"
    print_status "ArgoCD will now automatically sync all applications from your Git repository"
}

# Show access information
show_access_info() {
    print_status "Access Information:"
    echo
    print_success "ArgoCD UI Access:"
    print_status "  Run: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    print_status "  Open: http://localhost:8080"
    print_status "  Username: admin"
    print_status "  Password: $ARGOCD_PASSWORD"
    echo
    print_success "Grafana Access (after observability stack is deployed):"
    print_status "  Run: kubectl port-forward svc/prometheus-stack-grafana -n monitoring 3000:80"
    print_status "  Open: http://localhost:3000"
    print_status "  Username: admin"
    print_status "  Password: admin123 (or as configured)"
}

# Main execution
main() {
    echo "========================================"
    echo "GitOps Platform Setup (Existing Crossplane)"
    echo "========================================"
    echo
    
    check_cluster_access
    
    echo
    echo "Setup phases for existing Crossplane installation:"
    echo "4. Configure Providers"
    echo "5. Deploy Infrastructure"
    echo "6. Deploy Platform Services" 
    echo "7. Install ArgoCD"
    echo "8. Setup GitOps"
    echo
    
    read -p "Do you want to run all phases? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        configure_providers
        deploy_infrastructure
        deploy_platform_services
        install_argocd
        setup_gitops
        show_access_info
    else
        echo "You can run individual phases by calling the functions directly:"
        echo "- configure_providers"
        echo "- deploy_infrastructure"
        echo "- deploy_platform_services"
        echo "- install_argocd"
        echo "- setup_gitops"
    fi
}

# Export functions so they can be called individually
export -f configure_providers
export -f deploy_infrastructure  
export -f deploy_platform_services
export -f install_argocd
export -f setup_gitops
export -f show_access_info

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
