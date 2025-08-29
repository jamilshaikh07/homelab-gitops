# GitOps Infrastructure as Code: Managing Kubernetes Infrastructure with Crossplane and Argo CD

*How I built a fully automated GitOps pipeline for infrastructure management using Crossplane, Argo CD, and the App-of-Apps pattern*

## The Problem: Manual Infrastructure Management

Managing Kubernetes infrastructure traditionally involves:
- Manual `kubectl apply` commands
- Configuration drift between environments
- No version control for infrastructure changes
- Difficulty tracking who changed what and when
- Complex dependency management between components

What if we could treat infrastructure the same way we treat application code? Enter **GitOps for Infrastructure**.

## The Solution: GitOps + Crossplane + Argo CD

In this post, I'll show you how I built a complete GitOps infrastructure pipeline that:
- ✅ Manages infrastructure through Git commits
- ✅ Automatically syncs changes to Kubernetes
- ✅ Handles complex dependencies with sync waves
- ✅ Provides a clear audit trail of all changes
- ✅ Enables easy rollbacks and disaster recovery

### Architecture Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Git Repo  │───▶│   Argo CD   │───▶│ Crossplane  │───▶│ Kubernetes  │
│             │    │             │    │             │    │ Resources   │
│ YAML Files  │    │ GitOps Sync │    │ Provider    │    │ (MetalLB)   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

## Step 1: The App-of-Apps Pattern

The foundation of scalable GitOps is the **App-of-Apps pattern**. Instead of managing dozens of individual Argo CD applications, we create a root application that manages child applications.

```yaml
# argocd/app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: homelab-root
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
spec:
  project: default
  source:
    repoURL: https://github.com/jamilshaikh07/homelab-gitops.git
    targetRevision: main
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

This single application automatically discovers and manages all child applications in the `apps/` directory.

## Step 2: Crossplane Provider Setup

Crossplane allows us to manage any infrastructure through Kubernetes APIs. We start by installing the provider-kubernetes:

```yaml
# crossplane/provider-kubernetes/provider.yaml
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-kubernetes
  annotations:
    argocd.argoproj.io/sync-wave: "0"
spec:
  package: xpkg.upbound.io/crossplane-contrib/provider-kubernetes:v0.13.0
```

The key insight is using **sync waves** to ensure proper ordering:
- Wave 0: Install the provider
- Wave 1: Configure the provider + RBAC
- Wave 2: Create infrastructure resources

## Step 3: Infrastructure as Code with Crossplane Objects

Here's where the magic happens. Instead of directly applying Kubernetes resources, we use Crossplane `Object` resources to manage them:

```yaml
# metallb/metallb-ipaddresspool.yaml
apiVersion: kubernetes.crossplane.io/v1alpha1
kind: Object
metadata:
  name: metallb-ipaddresspool
  namespace: crossplane-system
  annotations:
    argocd.argoproj.io/sync-wave: "2"
spec:
  providerConfigRef:
    name: in-cluster
  forProvider:
    manifest:
      apiVersion: metallb.io/v1beta1
      kind: IPAddressPool
      metadata:
        name: homelab-pool
        namespace: metallb-system
      spec:
        addresses:
          - 10.20.0.81-10.20.0.99
```

This approach provides several benefits:
- **Dependency management**: Crossplane ensures the provider is ready before creating resources
- **Drift detection**: Crossplane continuously reconciles the desired state
- **Status reporting**: Rich status information about infrastructure health

## Step 4: RBAC - The Missing Piece

A critical aspect often overlooked is RBAC. Crossplane needs permissions to manage your infrastructure:

```yaml
# crossplane/provider-kubernetes/rbac.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: crossplane-provider-kubernetes-metallb
rules:
- apiGroups: ["metallb.io"]
  resources: ["ipaddresspools", "l2advertisements"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: crossplane-provider-kubernetes-metallb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: crossplane-provider-kubernetes-metallb
subjects:
- kind: ServiceAccount
  name: provider-kubernetes-xxxxx  # Dynamic name from provider
  namespace: crossplane-system
```

## Step 5: Testing the Complete Pipeline

The moment of truth! Let's verify our GitOps infrastructure pipeline:

```bash
# Check Argo CD applications
kubectl -n argocd get applications
NAME                             SYNC STATUS   HEALTH STATUS
crossplane-provider-kubernetes   Synced        Healthy
homelab-root                     Synced        Healthy
metallb-config                   Synced        Healthy

# Verify MetalLB resources were created
kubectl -n metallb-system get ipaddresspools.metallb.io
NAME           AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
homelab-pool   true          false             ["10.20.0.81-10.20.0.99"]

# Test LoadBalancer IP assignment
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=LoadBalancer --port=80
kubectl get svc nginx
NAME    TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
nginx   LoadBalancer   10.104.155.73   10.20.0.82    80:30114/TCP

# Verify connectivity
curl http://10.20.0.82
<!DOCTYPE html>
<html>
<head><title>Welcome to nginx!</title></head>
...
```

🎉 **Success!** Our infrastructure was created entirely through GitOps!

## Key Benefits Achieved

### 1. **Declarative Infrastructure**
- Infrastructure is defined in YAML files
- Version controlled alongside application code
- Easy to review changes through pull requests

### 2. **Automated Deployment**
- Git commits automatically trigger infrastructure changes
- No manual `kubectl apply` commands needed
- Consistent deployments across environments

### 3. **Dependency Management**
- Sync waves ensure correct installation order
- Crossplane handles resource dependencies automatically
- No more "resource not found" errors

### 4. **Audit Trail**
- Every infrastructure change is tracked in Git
- Easy to see who changed what and when
- Simple rollbacks using Git history

### 5. **Self-Healing**
- Argo CD continuously monitors for drift
- Automatically corrects manual changes
- Ensures desired state is maintained

## Repository Structure

```
homelab-gitops/
├── argocd/
│   └── app-of-apps.yaml              # Root GitOps application
├── apps/
│   ├── crossplane-provider-kubernetes-app.yaml
│   └── metallb-config-app.yaml       # Child applications
├── crossplane/
│   └── provider-kubernetes/
│       ├── provider.yaml             # Crossplane provider
│       ├── providerconfig.yaml       # Provider configuration
│       └── rbac.yaml                 # RBAC permissions
└── metallb/
    ├── metallb-ipaddresspool.yaml    # Infrastructure resources
    └── metallb-l2advertisement.yaml  # managed by Crossplane
```

## Lessons Learned

### 1. **API Versions Matter**
Different Crossplane provider versions use different API versions. Always check the provider documentation:
- `kubernetes.crossplane.io/v1alpha1` for provider-kubernetes v0.13.0
- `kubernetes.crossplane.io/v1alpha2` for newer versions

### 2. **RBAC is Critical**
Crossplane providers need explicit permissions to manage resources. Don't forget to:
- Create appropriate ClusterRoles
- Bind them to the provider's ServiceAccount
- Restart provider pods after RBAC changes

### 3. **Sync Waves Prevent Race Conditions**
Use sync waves to ensure proper ordering:
- `-1`: Root applications
- `0`: Providers and CRDs
- `1`: Provider configurations and RBAC
- `2+`: Infrastructure resources

### 4. **Bootstrap Process**
Even with GitOps, you need one manual step:
```bash
kubectl apply -f argocd/app-of-apps.yaml
```
After this, everything else is automated!

## What's Next?

This foundation enables managing any infrastructure through GitOps:
- **Databases**: PostgreSQL, MongoDB via operators
- **Networking**: Ingress controllers, service meshes
- **Storage**: Persistent volumes, backup solutions
- **Security**: Certificate management, policy engines
- **Monitoring**: Prometheus, Grafana, alerting

The same pattern scales to manage entire infrastructure portfolios across multiple clusters and environments.

## Conclusion

By combining Crossplane with Argo CD and the App-of-Apps pattern, we've created a powerful GitOps infrastructure pipeline that:
- Treats infrastructure as code
- Provides automated deployments
- Ensures consistent state management
- Enables easy scaling and maintenance

The result? Infrastructure changes are now as simple as creating a pull request. No more manual commands, no more configuration drift, and no more sleepless nights wondering if production matches your configuration files.

---

*Want to see the complete implementation? Check out the [homelab-gitops repository](https://github.com/jamilshaikh07/homelab-gitops) for all the code and configurations used in this post.*

## Tags
#GitOps #Kubernetes #Crossplane #ArgoCD #Infrastructure #DevOps #IaC #InfrastructureAsCode #Automation #CloudNative
