# Modern GitOps Platform with Crossplane and ArgoCD

A comprehensive GitOps platform setup using Crossplane for infrastructure management and ArgoCD for GitOps automation.

## 🎯 Objectives

- **Crossplane** to manage all infrastructure, platform, and Helm-based workloads
- **ArgoCD** as the GitOps engine to sync all manifests from Git to the cluster
- Complete declarative infrastructure with version control
- Automated deployment and management of platform services
- Comprehensive backup and disaster recovery strategy

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Git Repository                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │  Bootstrap  │ │ Crossplane  │ │      Applications       │ │
│  │   (ArgoCD)  │ │   (XRDs,    │ │    (Claims, Helm        │ │
│  │             │ │Compositions)│ │     Releases)           │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   ArgoCD (GitOps Engine)                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │   App of    │ │  Platform   │ │      Application        │ │
│  │    Apps     │ │   Services  │ │        Apps             │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Kubernetes Cluster                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐ │
│  │ Crossplane  │ │   Platform  │ │      Applications       │ │
│  │ Providers   │ │  Components │ │   (via Crossplane)      │ │
│  │   & XRDs    │ │(Ingress,etc)│ │                         │ │
│  └─────────────┘ └─────────────┘ └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

1. **Clone and Configure**
   ```bash
   git clone <your-repo>
   cd crossplane-gitops
   ```

2. **Update Configuration**
   - Edit `CONFIGURATION.md` and update all placeholders
   - Set your Git repository URLs in `argocd-apps/`
   - Configure network settings, domains, and credentials

3. **Run Setup**
   ```bash
   ./setup.sh
   ```

4. **Access ArgoCD UI**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   # Open http://localhost:8080
   # Username: admin
   # Password: (check setup.sh output)
   ```

## 📁 Repository Structure

```
├── README.md
├── GITOPS_SETUP_GUIDE.md      # Detailed setup guide
├── CONFIGURATION.md           # Configuration reference
├── DISASTER_RECOVERY.md       # DR strategy and procedures
├── setup.sh                   # Automated setup script
├── bootstrap/                 # Initial cluster setup
│   ├── namespaces.yaml
│   ├── argocd/
│   └── crossplane/
├── infrastructure/            # Infrastructure as Code
│   ├── crossplane/
│   │   ├── providers/
│   │   ├── xrds/             # Custom Resource Definitions
│   │   └── compositions/     # Infrastructure compositions
│   └── platform/             # Platform service claims
│       ├── storage/
│       ├── backup/
│       ├── ingress/
│       └── observability/
├── applications/              # Application deployments
│   ├── workloads/
│   └── system/
├── argocd-apps/              # ArgoCD application definitions
│   ├── app-of-apps.yaml
│   ├── infrastructure-apps.yaml
│   └── application-apps.yaml
└── secrets/                  # Secret management
    ├── external-secrets/
    └── sealed-secrets/
```

## 🔧 Technology Stack

### Core Platform
- **Kubernetes**: Taloslinux bare metal HA cluster
- **Crossplane**: Infrastructure and application management
- **ArgoCD**: GitOps continuous deployment
- **Helm**: Package management via Crossplane

### Infrastructure Services
- **Storage**: NFS CSI driver for persistent storage
- **Backup**: Velero for cluster backup and restore
- **Ingress**: NGINX Ingress Controller with MetalLB
- **Observability**: Prometheus, Grafana, Loki stack
- **Security**: External Secrets Operator, cert-manager

### Sample Applications
- **n8n**: Workflow automation platform
- **PostgreSQL**: Database for applications
- **Additional workloads**: Easily extensible

## 📋 Setup Phases

### Phase 1: Bootstrap
- Create required namespaces
- Basic cluster preparation

### Phase 2: Crossplane Installation
- Install Crossplane core
- Deploy required providers (Helm, Kubernetes)
- Configure provider permissions

### Phase 3: ArgoCD Installation
- Install ArgoCD with Helm
- Configure basic settings
- Secure admin access

### Phase 4: Infrastructure Deployment
- Apply Crossplane XRDs and Compositions
- Deploy infrastructure abstractions
- Configure provider configurations

### Phase 5: Platform Services
- Deploy storage solutions (NFS CSI)
- Setup backup system (Velero)
- Configure ingress stack (NGINX + MetalLB)
- Deploy observability stack (Prometheus + Grafana + Loki)

### Phase 6: GitOps Automation
- Configure App of Apps pattern
- Setup automated sync policies
- Deploy application workloads

## 🔒 Security and Secrets Management

### External Secrets Operator (Recommended)
- Integrates with external secret stores
- Supports AWS Secrets Manager, Azure Key Vault, HashiCorp Vault
- Automatic secret rotation and updates

### Sealed Secrets (Alternative)
- Client-side encryption for Git storage
- Controller-based decryption in cluster
- Suitable for smaller deployments

### Best Practices
- Never commit plain text secrets to Git
- Use separate repositories for sensitive configurations
- Implement proper RBAC for secret access
- Regular secret rotation

## 📊 Monitoring and Observability

### Prometheus Stack
- Metrics collection from all platform components
- Custom dashboards for Crossplane and ArgoCD
- Alerting for platform health and performance

### Grafana Dashboards
- Infrastructure overview
- Application performance monitoring
- GitOps deployment metrics
- Backup and restore status

### Loki for Logs
- Centralized log aggregation
- Integration with Grafana for unified observability
- Log-based alerting and troubleshooting

## 🔄 Backup and Disaster Recovery

### Multi-Layer Backup Strategy
1. **Git Repository**: Source of truth protection
2. **Cluster State**: Velero for resources and data
3. **Persistent Storage**: NAS-level backups
4. **Application Data**: Database dumps and exports

### Recovery Scenarios
- Complete cluster loss recovery
- Partial application failure recovery
- Configuration drift remediation
- Data corruption recovery

### Testing and Validation
- Monthly DR simulations
- Automated backup verification
- Recovery time objectives (RTO) monitoring

## 🛠️ Operations and Maintenance

### Day 1 Operations
- Initial setup and configuration
- Security hardening
- Integration testing

### Day 2 Operations
- Application lifecycle management
- Scaling and capacity planning
- Security updates and patches
- Backup verification and testing

### Troubleshooting
- ArgoCD sync issues
- Crossplane resource debugging
- Application deployment problems
- Performance optimization

## 📚 Documentation

- **[Setup Guide](GITOPS_SETUP_GUIDE.md)**: Comprehensive step-by-step setup
- **[Configuration Reference](CONFIGURATION.md)**: All customizable parameters
- **[Disaster Recovery](DISASTER_RECOVERY.md)**: Complete DR strategy and procedures

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test thoroughly
4. Submit a pull request
5. Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- Check the troubleshooting section in the setup guide
- Review ArgoCD and Crossplane documentation
- Open issues for bugs or feature requests
- Join the community discussions

---

**Note**: This is a production-ready GitOps platform setup. Please review all configurations, especially security settings and network parameters, before deploying to production environments.

