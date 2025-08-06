# Disaster Recovery Strategy

This document outlines the disaster recovery strategy for the GitOps platform.

## Overview

The disaster recovery strategy is built on multiple layers:
1. **Git Repository Backup** - Source of truth protection
2. **Cluster State Backup** - Velero for cluster resources and data
3. **Infrastructure as Code** - Declarative infrastructure management
4. **Automated Recovery** - Self-healing through ArgoCD

## 1. Git Repository Backup

### Strategy
- Primary Git repository on GitHub/GitLab with redundancy
- Mirror repositories for critical infrastructure
- Regular automated backups to multiple locations

### Implementation
```bash
# Create a backup script for Git repositories
#!/bin/bash
BACKUP_DIR="/backup/git-repos"
REPOS=("https://github.com/your-org/gitops-platform.git")

for repo in "${REPOS[@]}"; do
    repo_name=$(basename "$repo" .git)
    git clone --mirror "$repo" "$BACKUP_DIR/$repo_name.git"
done
```

### Recovery Process
1. Restore Git repository from backup
2. Update ArgoCD application source URLs if necessary
3. ArgoCD will automatically sync all applications

## 2. Cluster State Backup with Velero

### Backup Strategy
- **Daily backups**: All namespaces except system namespaces
- **Weekly backups**: Full cluster backup including system components
- **On-demand backups**: Before major changes

### Backup Schedules
```yaml
# Daily backup (configured in Velero)
schedules:
  daily-backup:
    schedule: "0 1 * * *"  # 1 AM daily
    template:
      ttl: "720h"  # 30 days retention
      includedNamespaces: ["*"]
      excludedNamespaces:
        - kube-system
        - kube-public
        - kube-node-lease

  weekly-backup:
    schedule: "0 2 * * 0"  # 2 AM on Sundays
    template:
      ttl: "2160h"  # 90 days retention
      includedNamespaces: ["*"]
```

### Storage Backup
- Persistent volumes are snapshotted using CSI snapshots
- NFS data is backed up separately using NAS backup solutions
- Database dumps for critical applications

## 3. Recovery Procedures

### Scenario 1: Complete Cluster Loss

#### Prerequisites
- New Kubernetes cluster available
- Access to Git repository
- Access to Velero backup storage
- NFS storage restored or available

#### Recovery Steps

1. **Bootstrap New Cluster**
```bash
# Install essential components
kubectl apply -f bootstrap/namespaces.yaml

# Install Crossplane
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm install crossplane crossplane-stable/crossplane \
  --namespace crossplane-system \
  --create-namespace

# Install ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace
```

2. **Restore Velero**
```bash
# Install Velero
helm install velero vmware-tanzu/velero \
  --namespace velero \
  --create-namespace \
  --values velero-values.yaml

# Restore from backup
velero restore create --from-backup daily-backup-20231201-010000
```

3. **Restore GitOps**
```bash
# Apply App of Apps
kubectl apply -f argocd-apps/app-of-apps.yaml

# ArgoCD will sync all applications automatically
```

### Scenario 2: Partial Application Failure

#### Recovery Steps
1. **Identify Failed Applications**
```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# Check specific application
argocd app get <application-name>
```

2. **Restore from Backup**
```bash
# List available backups
velero backup get

# Restore specific namespace
velero restore create --from-backup <backup-name> \
  --include-namespaces <namespace>
```

3. **Force ArgoCD Sync**
```bash
# Sync specific application
argocd app sync <application-name>

# Hard refresh and sync
argocd app sync <application-name> --force
```

### Scenario 3: Configuration Drift

#### Detection
- ArgoCD OutOfSync status
- Manual changes detected
- Configuration validation failures

#### Recovery Steps
1. **Review Changes**
```bash
# Check application diff
argocd app diff <application-name>

# View sync status
argocd app get <application-name>
```

2. **Restore from Git**
```bash
# Enable auto-sync if disabled
argocd app set <application-name> --sync-policy automated

# Force sync from Git
argocd app sync <application-name> --force --replace
```

## 4. Data Protection

### Database Backups
- Automated database dumps for PostgreSQL instances
- Point-in-time recovery capabilities
- Cross-regional backup replication

### Persistent Volume Backups
- CSI volume snapshots for block storage
- File-level backups for NFS shares
- Backup verification and testing

## 5. Testing and Validation

### Regular DR Testing
- Monthly recovery simulations
- Quarterly full disaster recovery tests
- Annual chaos engineering exercises

### Test Procedures
```bash
# Test backup restoration
velero restore create test-restore-$(date +%Y%m%d) \
  --from-backup <latest-backup> \
  --namespace-mappings source-ns:test-ns

# Validate ArgoCD sync
argocd app sync --dry-run <application-name>

# Test application functionality
kubectl run test-pod --image=busybox --rm -it -- /bin/sh
```

## 6. Monitoring and Alerting

### Backup Monitoring
- Velero backup success/failure alerts
- Backup storage utilization monitoring
- ArgoCD sync status monitoring

### Health Checks
- Application availability monitoring
- Data integrity checks
- Performance baseline monitoring

### Alert Configuration
```yaml
# Prometheus alert for failed backups
- alert: VeleroBackupFailed
  expr: velero_backup_failure_total > 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Velero backup failed"
    description: "Backup {{ $labels.backup_name }} has failed"

# ArgoCD sync failure alert
- alert: ArgoCDSyncFailed
  expr: argocd_app_health_status{health_status!="Healthy"} > 0
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "ArgoCD application unhealthy"
    description: "Application {{ $labels.name }} is not healthy"
```

## 7. Documentation and Runbooks

### Emergency Contacts
- Platform team on-call rotation
- Infrastructure team escalation
- Vendor support contacts

### Recovery Runbooks
- Step-by-step recovery procedures
- Troubleshooting guides
- Known issues and workarounds

### Post-Incident Reviews
- Root cause analysis
- Process improvements
- Documentation updates

## 8. Best Practices

### Prevention
- Regular backup testing
- Configuration validation
- Change management processes
- Infrastructure as Code practices

### Response
- Clear escalation procedures
- Communication protocols
- Status page updates
- Stakeholder notifications

### Recovery
- Gradual service restoration
- Data integrity verification
- Performance validation
- User acceptance testing

## 9. Compliance and Auditing

### Backup Retention
- Regulatory compliance requirements
- Data retention policies
- Secure backup storage

### Audit Trails
- Change tracking in Git
- Backup and restore logs
- Access control auditing

### Security Considerations
- Encrypted backups
- Secure key management
- Access control for recovery procedures
