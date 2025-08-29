# Homelab GitOps

This repository manages your homelab cluster infrastructure using GitOps principles via Argo CD and Crossplane. Argo CD provides the GitOps controller and UI; Crossplane manages infrastructure provisioning and Helm deployments inside the cluster.

## 🏗️ Architecture Overview

### GitOps Pattern: App of Apps
- **Root Application**: `argocd/app-of-apps.yaml` - Entry point that manages all child applications
- **Child Applications**: Located in `apps/` directory, each managing specific infrastructure components
- **Sync Waves**: Ordered deployment ensuring proper dependency management

### Infrastructure Components
1. **Crossplane Providers**: Infrastructure management and Helm chart deployment capabilities
2. **MetalLB**: LoadBalancer implementation with reserved IP pool (10.20.0.81-10.20.0.99)  
3. **NGINX Ingress**: Ingress controller deployed via Helm through Crossplane

## 📚 Components Documentation

### App of Apps Pattern
- **Root app**: `argocd/app-of-apps.yaml` points to `apps/` directory containing all child applications
- **Child applications**:
  - `crossplane-provider-kubernetes-app.yaml` - Manages in-cluster Kubernetes resources
  - `crossplane-provider-helm-app.yaml` - Manages Helm chart deployments  
  - `metallb-config-app.yaml` - MetalLB configuration via Crossplane Objects
  - `nginx-ingress-app.yaml` - NGINX Ingress Controller via Crossplane Helm Release

### Crossplane Provider: Kubernetes
- **Installation**: `crossplane/provider-kubernetes/provider.yaml` (v0.13.0)
- **Configuration**: `crossplane/provider-kubernetes/providerconfig.yaml` uses `InjectedIdentity`
- **RBAC**: `crossplane/provider-kubernetes/rbac.yaml` with MetalLB CRD permissions
- **Purpose**: Enables Crossplane to manage in-cluster Kubernetes resources

### Crossplane Provider: Helm  
- **Installation**: `crossplane/provider-helm/provider.yaml` (v0.18.1)
- **Configuration**: `crossplane/provider-helm/providerconfig.yaml` for in-cluster Helm operations
- **RBAC**: `crossplane/provider-helm/rbac.yaml` with comprehensive CRD and namespace permissions
- **Purpose**: Enables GitOps-managed Helm chart deployments

### MetalLB Configuration
Applied via Crossplane `Object` resources in `metallb/`:
- **IP Pool**: `metallb-ipaddresspool.yaml` creates `IPAddressPool` named `homelab-pool` with range `10.20.0.81-10.20.0.99`
- **L2 Advertisement**: `metallb-l2advertisement.yaml` creates `L2Advertisement` for pool advertisement
- **Result**: LoadBalancer Services automatically receive IPs from the reserved range

### NGINX Ingress Controller
Deployed via Crossplane `Release` in `nginx-ingress/`:
- **Deployment**: `nginx-ingress-release.yaml` uses official nginx-ingress Helm chart (v2.2.2)
- **Service Type**: LoadBalancer (gets IP from MetalLB pool)  
- **Configuration**: Managed entirely through GitOps

## 🔄 Sync Wave Strategy
Proper dependency ordering using Argo CD sync waves:
- **Wave -1**: Root app-of-apps application
- **Wave 0**: Crossplane providers installation
- **Wave 1**: Provider configurations and RBAC
- **Wave 2**: MetalLB configuration  
- **Wave 3**: NGINX Ingress deployment

## 🗑️ GitOps Deletion Workflow

### Enhanced Deletion Process
Our repository implements an enhanced GitOps deletion workflow that reduces manual intervention:

#### Traditional Approach (4 steps - NOT RECOMMENDED):
1. Remove from Git and sync
2. Remove finalizers manually
3. Delete Crossplane resources manually  
4. Delete Argo CD applications manually

#### Enhanced Approach (3 Git operations - RECOMMENDED):
1. **Remove from kustomization.yaml**: Remove application reference
2. **Remove application file**: Delete the app YAML file
3. **Remove configuration directory**: Delete the component directory

**Key Enhancements**:
- **Finalizers**: `resources-finalizer.argocd.argoproj.io` ensures proper cleanup order
- **Deletion Policies**: `deletionPolicy: Delete` on Crossplane resources for automatic cleanup
- **Automated Sync**: `prune: true` and `selfHeal: true` for hands-off operations

### Troubleshooting Stuck Deletions
If resources get stuck during deletion (usually due to creation failures):

```bash
# Check Argo CD applications
kubectl -n argocd get applications

# Check Crossplane releases  
kubectl -n crossplane-system get releases.helm.crossplane.io

# For stuck resources, remove finalizers manually:
kubectl -n argocd patch application <app-name> --type json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
kubectl -n crossplane-system patch release <release-name> --type json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
```

## ✅ Verification Steps

### Argo CD Health Check
```bash
kubectl -n argocd get applications
# All applications should show: SYNC STATUS=Synced, HEALTH STATUS=Healthy
```

### MetalLB Verification  
```bash
# Check IP pool configuration
kubectl -n metallb-system get ipaddresspools.metallb.io

# Check L2 advertisement
kubectl -n metallb-system get l2advertisements.metallb.io

# Test LoadBalancer IP assignment
kubectl create service loadbalancer test-lb --tcp=80:80
kubectl get svc test-lb  # Should show EXTERNAL-IP from 10.20.0.81-10.20.0.99 range
kubectl delete svc test-lb
```

### NGINX Ingress Verification
```bash
# Check NGINX Ingress pods
kubectl -n nginx-ingress get pods

# Check LoadBalancer service
kubectl -n nginx-ingress get svc nginx-ingress-controller
# Should show EXTERNAL-IP from MetalLB pool

# Test connectivity
curl -I http://<EXTERNAL-IP>  # Should return 404 (expected for unconfigured ingress)
```

### Crossplane Provider Status
```bash
# Check provider installations
kubectl get providers

# Check provider configurations  
kubectl get providerconfigs

# Check Crossplane-managed resources
kubectl get objects  # For provider-kubernetes managed resources
kubectl get releases  # For provider-helm managed resources
```

## 📋 Prerequisites

- **Argo CD**: Installed and configured in `argocd` namespace
- **Crossplane**: Core installation running in `crossplane-system` namespace  
- **MetalLB**: Installed in `metallb-system` namespace
- **GitHub Access**: Private repository access configured (PAT recommended)
- **Kubernetes Cluster**: With sufficient RBAC permissions for Crossplane

## 🔧 Configuration Files Reference

### Directory Structure
```
├── argocd/
│   └── app-of-apps.yaml           # Root GitOps application
├── apps/  
│   ├── kustomization.yaml         # Child application registry
│   ├── crossplane-provider-kubernetes-app.yaml
│   ├── crossplane-provider-helm-app.yaml  
│   ├── metallb-config-app.yaml
│   └── nginx-ingress-app.yaml
├── crossplane/
│   ├── provider-kubernetes/       # In-cluster resource management
│   └── provider-helm/             # Helm chart deployment
├── metallb/                       # LoadBalancer IP configuration
├── nginx-ingress/                 # Ingress controller deployment
└── blog/                          # Documentation and guides
```

## 🚀 Quick Start

1. **Install Prerequisites**: Ensure Argo CD, Crossplane, and MetalLB are installed
2. **Configure Repository Access**: Set up GitHub PAT for private repository access
3. **Deploy Root Application**: Apply `argocd/app-of-apps.yaml` to your cluster
4. **Monitor Deployment**: Watch applications sync in Argo CD UI
5. **Verify Components**: Run verification commands above
6. **Test LoadBalancer**: Create a test service and verify IP assignment

## 📞 Support & Contributions

For issues, improvements, or questions:
- Review the troubleshooting section above
- Check the blog posts for detailed explanations  
- Examine sync waves and dependency ordering
- Verify RBAC permissions for stuck resources
