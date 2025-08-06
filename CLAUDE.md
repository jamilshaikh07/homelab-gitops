# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a homelab GitOps platform using Crossplane for infrastructure management and ArgoCD for GitOps automation. The architecture follows a declarative approach where Crossplane manages all infrastructure components (including Helm releases) and ArgoCD syncs everything from Git to the Kubernetes cluster.

## Key Commands

### Setup and Deployment
```bash
# Initial platform setup (bootstraps Crossplane, ArgoCD, and core infrastructure)
./setup.sh

# Individual setup phases (if needed)
source setup.sh
bootstrap_setup
install_crossplane  
install_argocd
configure_providers
deploy_infrastructure
setup_argocd_apps

# Access ArgoCD UI locally
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Username: admin, Password: get from setup.sh output
```

### Validation and Troubleshooting
```bash
# Check Crossplane providers status
kubectl get providers.pkg.crossplane.io
kubectl describe provider.pkg.crossplane.io <provider-name>

# Check ArgoCD applications status  
kubectl get applications -n argocd
kubectl describe application <app-name> -n argocd

# Validate Crossplane compositions and XRDs
kubectl get compositions
kubectl get xrds
kubectl get claims --all-namespaces

# Check infrastructure deployment status
kubectl get releases.helm.crossplane.io --all-namespaces
kubectl get objects.kubernetes.crossplane.io --all-namespaces
```

## Architecture and Structure

### Core Philosophy
- **Crossplane**: Manages ALL infrastructure components via Compositions and Claims
- **ArgoCD**: GitOps engine that syncs manifests from Git to cluster using App-of-Apps pattern
- **NAS Integration**: Uses NFS CSI with storage at `10.20.0.10:/mnt/pool1/kubernetes`

### Directory Structure
- `bootstrap/`: Initial setup for Crossplane and ArgoCD
- `infrastructure/crossplane/`: XRDs and Compositions defining infrastructure abstractions
- `infrastructure/platform/`: Infrastructure Claims (storage, backup, ingress, observability)
- `applications/workloads/`: Application Claims managed by Crossplane
- `argocd-apps/`: ArgoCD Application definitions (App-of-Apps pattern)
- `secrets/`: Secret management (External Secrets Operator)

### Key Infrastructure Components
1. **Storage**: NFS CSI driver connected to NAS at `10.20.0.10:/mnt/pool1/kubernetes`
2. **Observability**: Prometheus + Grafana + Loki stack via Crossplane Composition
3. **Ingress**: NGINX Ingress Controller with MetalLB load balancer
4. **Backup**: Velero for cluster and application backup
5. **Applications**: n8n workflow automation (extensible for more workloads)

### Crossplane Pattern
- **XRDs** (`infrastructure/crossplane/xrds/`): Define custom resource schemas
- **Compositions** (`infrastructure/crossplane/compositions/`): Template infrastructure deployments
- **Claims** (`infrastructure/platform/`, `applications/`): Instantiate infrastructure via simplified parameters

### ArgoCD Pattern
- **App-of-Apps**: Root application (`argocd-apps/app-of-apps.yaml`) manages all other applications
- **Automated Sync**: All applications configured with `automated: {prune: true, selfHeal: true}`
- **Repository**: Points to `https://github.com/jamilshaikh07/homelab-gitops.git`

## Configuration Requirements

Before deployment, update these critical configurations:

### Network Settings
- MetalLB IP range in `infrastructure/platform/ingress/ingress-stack-claim.yaml`
- NFS server details: `10.20.0.10:/mnt/pool1/kubernetes` in storage configurations

### Git Repository URLs
Update repository URLs in all `argocd-apps/*.yaml` files to match your Git repository.

### Domain Configuration
- ArgoCD: Update domain in bootstrap ArgoCD configs
- Grafana: Update domain in observability stack claim
- Applications: Update ingress domains in workload claims

### Security
- Change default passwords in observability and application configurations
- Configure proper backup credentials for Velero S3 integration

## Development Workflow

1. **Infrastructure Changes**: Modify XRDs, Compositions, or Claims locally
2. **Application Changes**: Update workload Claims or add new applications
3. **Git Push**: Commit and push changes to repository
4. **ArgoCD Sync**: ArgoCD automatically detects and applies changes
5. **Validation**: Monitor ArgoCD UI and check resource status with kubectl

## Troubleshooting

### Common Issues
- **Provider not healthy**: Check provider installation and RBAC permissions
- **ArgoCD sync failures**: Verify Git repository access and manifest syntax
- **Resource creation stuck**: Check Crossplane provider logs and resource events
- **Storage issues**: Verify NAS connectivity and NFS CSI driver status

### Debug Commands
```bash
# Crossplane debugging
kubectl logs -n crossplane-system deployment/crossplane
kubectl get events --sort-by=.metadata.creationTimestamp

# ArgoCD debugging  
kubectl logs -n argocd deployment/argocd-server
kubectl get events -n argocd

# Provider-specific debugging
kubectl logs -n crossplane-system deployment/provider-helm-*
kubectl logs -n crossplane-system deployment/provider-kubernetes-*
```

## Important Notes

- Never manually modify resources managed by Crossplane - always update via Claims
- All infrastructure is declared in Git - avoid imperative kubectl commands for managed resources
- The platform is designed for declarative, version-controlled infrastructure management
- NAS storage dependency: Ensure `10.20.0.10:/mnt/pool1/kubernetes` is accessible before deployment