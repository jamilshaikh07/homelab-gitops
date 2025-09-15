# Homelab GitOps

This repository implements the ArgoCD App of Apps pattern for managing a homelab Kubernetes cluster using GitOps principles.

## Overview

The App of Apps pattern allows you to manage multiple ArgoCD applications from a single repository. This approach provides:

- **Centralized Management**: All applications are defined in one place
- **Version Control**: Application configurations are versioned with Git
- **Automated Deployment**: Changes are automatically deployed to the cluster
- **Consistency**: Ensures all environments follow the same patterns

## Repository Structure

```
homelab-gitops/
├── app-of-apps.yaml          # Main ArgoCD Application that manages all others
├── apps/                     # Individual ArgoCD Application manifests
│   ├── cert-manager.yaml    
│   ├── prometheus-stack.yaml
│   └── homelab-services.yaml
├── apps-disabled/            # Disabled applications (not deployed)
│   ├── nginx-ingress.yaml   # NGINX Ingress (disabled)
│   └── README.md
├── manifests/                # Kubernetes manifests for custom applications
│   └── homelab-services/     # Custom application manifests
└── README.md
```

## Getting Started

### Prerequisites

1. A Kubernetes cluster (k3s, k8s, etc.)
2. ArgoCD installed in the cluster
3. This repository accessible from your cluster

### Installation

1. **Clone this repository** (if not already done):
   ```bash
   git clone https://github.com/jamilshaikh07/homelab-gitops.git
   cd homelab-gitops
   ```

2. **Deploy the App of Apps**:
   ```bash
   kubectl apply -f app-of-apps.yaml
   ```

3. **Access ArgoCD UI**:
   ```bash
   # Get ArgoCD admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   
   # Port forward to access UI
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

4. **View in ArgoCD**: Open https://localhost:8080 and login with admin credentials

## Applications Included

### Infrastructure Applications

- **cert-manager**: Automatic TLS certificate management
- **prometheus-stack**: Complete monitoring stack (Prometheus, Grafana, AlertManager)

### Disabled Applications

- **nginx-ingress**: Ingress controller for external access (currently disabled)

### Custom Applications

- **homelab-services**: Custom applications specific to your homelab

## Adding New Applications

### Method 1: Helm Chart Application

Create a new file in the `apps/` directory:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: your-app-name
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: your-namespace
    server: https://kubernetes.default.svc
  project: default
  source:
    chart: chart-name
    repoURL: https://helm-repo-url
    targetRevision: chart-version
    helm:
      values: |
        # Your helm values here
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Method 2: Git Repository Application

For custom Kubernetes manifests:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: your-app-name
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: your-namespace
    server: https://kubernetes.default.svc
  project: default
  source:
    path: manifests/your-app-path
    repoURL: https://github.com/jamilshaikh07/homelab-gitops
    targetRevision: main
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Managing Applications

### Disabling Applications

To disable an application without deleting its configuration:

1. **Move to disabled directory**:
   ```bash
   mv apps/app-name.yaml apps-disabled/
   ```

2. **Commit changes**:
   ```bash
   git add apps-disabled/app-name.yaml
   git commit -m "Disable app-name"
   git push
   ```

### Re-enabling Applications

To re-enable a disabled application:

1. **Move back to apps directory**:
   ```bash
   mv apps-disabled/app-name.yaml apps/
   ```

2. **Commit changes**:
   ```bash
   git add apps/app-name.yaml
   git commit -m "Re-enable app-name"
   git push
   ```

## Configuration

### Sync Policies

All applications are configured with automated sync policies:

- **prune: true**: Removes resources deleted from Git
- **selfHeal: true**: Corrects manual changes to match Git state
- **CreateNamespace=true**: Automatically creates target namespaces

### Customization

To customize any application:

1. Edit the corresponding file in the `apps/` directory
2. Commit and push changes
3. ArgoCD will automatically detect and apply changes

## Monitoring

Monitor your applications through:

- **ArgoCD UI**: Application status and sync state
- **Grafana**: Metrics and dashboards (if prometheus-stack is enabled)
- **kubectl**: Direct cluster inspection

## Troubleshooting

### Common Issues

1. **Application not syncing**:
   ```bash
   argocd app sync <app-name>
   ```

2. **Check application status**:
   ```bash
   argocd app get <app-name>
   ```

3. **View application logs**:
   ```bash
   kubectl logs -n argocd deployment/argocd-application-controller
   ```

### Manual Sync

If automatic sync is disabled or failing:

```bash
argocd app sync app-of-apps
```

## Security Considerations

- Review all Helm values and manifests before deployment
- Use secrets management for sensitive data
- Regularly update application versions
- Monitor for security vulnerabilities

## Contributing

1. Create a feature branch
2. Make your changes
3. Test in a development environment
4. Submit a pull request

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [GitOps Principles](https://opengitops.dev/)