# Homelab GitOps Repository Setup Guide

## Create Your Dedicated GitOps Repository

### 1. Create New Repository
```bash
# Create a new repository on GitHub/GitLab
# Repository name suggestion: "homelab-gitops" or "k8s-platform"

# Clone the new empty repository
git clone https://github.com/jamilshaikh07/homelab-gitops.git
cd homelab-gitops
```

### 2. Copy GitOps Structure
```bash
# Copy the entire crossplane-gitops directory to your new repo
cp -r /path/to/tfaz/homelab/crossplane-gitops/* .

# Initialize git and make initial commit
git add .
git commit -m "Initial GitOps platform setup

- Crossplane compositions for infrastructure management
- ArgoCD applications for GitOps automation
- Platform services: storage, ingress, observability, backup
- Application deployments via Helm releases
"

git push origin main
```

### 3. Update Repository URLs
After pushing to your new repo, update these files with the new repository URL:

```bash
# Files to update:
- argocd-apps/app-of-apps.yaml
- argocd-apps/infrastructure-apps.yaml  
- argocd-apps/application-apps.yaml

# Replace with your new repo URL:
repoURL: https://github.com/jamilshaikh07/homelab-gitops.git
```

### 4. Repository Structure Benefits

```
homelab-gitops/                    # Dedicated GitOps repository
├── README.md                      # Platform documentation
├── bootstrap/                     # Bootstrap components
├── infrastructure/                # Infrastructure as Code
├── applications/                  # Application deployments
├── argocd-apps/                  # ArgoCD application definitions
├── secrets/                      # Secret management
└── docs/                         # Additional documentation
```

vs.

```
tfaz/                             # Mixed workspace repository
├── ansible/                      # Configuration management
├── beamer/                       # Development projects
├── crossplane/                   # Mixed Crossplane files
├── homelab/
│   ├── crossplane-gitops/        # GitOps platform (buried)
│   ├── flux/                     # Other GitOps experiments
│   └── proxmox-homelab/          # Infrastructure code
├── k8s/                          # Various Kubernetes files
├── terraform/                    # Infrastructure provisioning
└── ww/                           # Work projects
```

## Benefits of Dedicated Repository

### Clean GitOps Workflow
- Pure infrastructure/platform code
- Clear commit history for changes
- Focused pull requests and reviews
- Better CI/CD pipeline integration

### Team Collaboration
- Clear repository purpose
- Easier onboarding for team members
- Better issue tracking and project management
- Focused documentation

### Security and Compliance
- Dedicated access controls
- Branch protection for production
- Audit trail for infrastructure changes
- Secrets management isolation

### ArgoCD Integration
- Cleaner application definitions
- Better sync performance
- Easier troubleshooting
- Clear application boundaries

## Migration Steps

1. **Create new repository**: `homelab-gitops`
2. **Copy GitOps files**: From `tfaz/homelab/crossplane-gitops/`
3. **Update repository URLs**: In ArgoCD application files
4. **Test locally**: Run setup scripts
5. **Deploy to cluster**: Use the new repository
6. **Archive old structure**: Keep in tfaz for reference

## Keeping tfaz Repository

You can keep your `tfaz` repository for:
- Development and experimentation
- Ansible playbooks
- Terraform modules
- Learning and testing

While using the dedicated `homelab-gitops` repository for:
- Production platform management
- Infrastructure as Code
- Application deployments
- GitOps workflows
