# Configuration Files Reference

This document provides important configuration values that need to be customized for your environment.

## Network Configuration

### MetalLB IP Range
Update the IP range in `infrastructure/platform/ingress/ingress-stack-claim.yaml`:
```yaml
metallb:
  enabled: true
  ipPool: "192.168.1.240-192.168.1.250"  # Update to match your network
```

### NFS Storage Configuration
Update NFS server details in `infrastructure/platform/storage/nfs-csi-setup.yaml`:
```yaml
parameters:
  server: 192.168.1.100  # Replace with your NAS IP
  share: /volume1/kubernetes  # Replace with your NFS share path
```

## Domain Configuration

### ArgoCD Domain
Update in `bootstrap/argocd/argocd-install.yaml`:
```yaml
global:
  domain: argocd.your-domain.com  # Replace with your domain
```

### Grafana Domain
Update in `infrastructure/platform/observability/observability-stack-claim.yaml`:
```yaml
grafana:
  domain: "grafana.your-domain.com"  # Replace with your domain
```

### Application Domains
Update application domains in their respective files:
- `applications/workloads/n8n/n8n-release.yaml`

## Git Repository Configuration

Update the following files with your Git repository URL:
- `argocd-apps/app-of-apps.yaml`
- `argocd-apps/infrastructure-apps.yaml`
- `argocd-apps/application-apps.yaml`

Replace:
```yaml
repoURL: https://github.com/YOUR_USERNAME/YOUR_REPO.git
```

## Security Configuration

### Passwords and Secrets
Update default passwords in:
- `infrastructure/platform/observability/observability-stack-claim.yaml` (Grafana admin password)
- `applications/workloads/n8n/n8n-release.yaml` (Database passwords, encryption keys)
- `infrastructure/platform/backup/velero-release.yaml` (AWS credentials)

### TLS Certificates
Configure cert-manager and cluster issuers for automatic TLS certificate management.

## Backup Configuration

### Velero S3 Configuration
Update in `infrastructure/platform/backup/velero-release.yaml`:
```yaml
configuration:
  backupStorageLocation:
  - name: default
    provider: aws
    bucket: your-backup-bucket  # Your S3 bucket name
    config:
      region: us-east-1  # Your AWS region
      s3Url: https://s3.amazonaws.com  # Your S3 endpoint
```

### AWS Credentials
Update the Velero credentials secret with your AWS access keys.

## Monitoring Configuration

### Storage Classes
Ensure all storage class references point to your available storage classes:
- Default: `nfs-csi`
- Alternative options: `local-path`, `longhorn`, etc.

### Resource Limits
Adjust resource requests and limits based on your cluster capacity:
- Memory allocations
- CPU requests
- Storage sizes

## High Availability Configuration

For production environments, consider:
- Multiple replicas for critical components
- Pod disruption budgets
- Anti-affinity rules
- Node selectors for workload placement

## Custom Applications

To add new applications:
1. Create a new directory under `applications/workloads/`
2. Define Helm releases or Kubernetes manifests
3. ArgoCD will automatically sync the new applications
