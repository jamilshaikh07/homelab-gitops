# 🏠 Homelab GitOps Platform with Crossplane & ArgoCD

A production-ready GitOps platform for homelab environments using **Crossplane** for infrastructure management and **ArgoCD** for continuous deployment. This setup provides declarative infrastructure management with the power of GitOps workflows.

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Git Repository (Source of Truth)           │
│  ┌──────────────┐ ┌─────────────────┐ ┌─────────────────────────────┐ │
│  │   Bootstrap  │ │   Infrastructure │ │        Applications         │ │
│  │  (Initial    │ │   (Crossplane    │ │     (Workloads via          │ │
│  │   Setup)     │ │   Compositions)  │ │      Crossplane)            │ │
│  └──────────────┘ └─────────────────┘ └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                     │ Git Sync
                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    ArgoCD (GitOps Engine)                           │
│  ┌──────────────┐ ┌─────────────────┐ ┌─────────────────────────────┐ │
│  │  App-of-Apps │ │ Infrastructure  │ │     Application Apps        │ │
│  │  (Orchestrates│ │    Services     │ │   (Workload Management)     │ │
│  │   all apps)  │ │ (Platform Infra)│ │                             │ │
│  └──────────────┘ └─────────────────┘ └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                     │ Creates Claims
                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Crossplane (Infrastructure Engine)             │
│  ┌──────────────┐ ┌─────────────────┐ ┌─────────────────────────────┐ │
│  │    Claims    │ │   Composite     │ │      Managed Resources      │ │
│  │ (What you    │ │   Resources     │ │   (Actual Infrastructure)   │ │
│  │   want)      │ │ (Crossplane XRs)│ │   (Helm, K8s Objects)       │ │
│  └──────────────┘ └─────────────────┘ └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                     │ Provisions
                                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster (3-Node HA)                   │
│  ┌──────────────┐ ┌─────────────────┐ ┌─────────────────────────────┐ │
│  │   Storage    │ │    Networking   │ │      Applications           │ │
│  │  (NFS CSI)   │ │  (MetalLB +     │ │   (n8n, Databases, etc.)    │ │
│  │   Backup     │ │   Nginx Ingress)│ │                             │ │
│  │  (Velero)    │ │   Observability │ │                             │ │
│  │              │ │ (Prometheus/    │ │                             │ │
│  │              │ │  Grafana/Loki)  │ │                             │ │
│  └──────────────┘ └─────────────────┘ └─────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## 🗂️ Complete File Structure & Use Cases

```
homelab-gitops/
├── 📝 README.md                           # This comprehensive guide
├── ⚙️ setup.sh                            # Automated deployment script
├── ⚙️ setup-existing-crossplane.sh        # Setup for existing Crossplane
├── 📋 CLAUDE.md                           # Claude AI assistant context
├── 📋 CONFIGURATION.md                    # Configuration parameters
├── 🔄 DISASTER_RECOVERY.md                # Backup & recovery procedures
├── 📋 GITOPS_SETUP_GUIDE.md              # Step-by-step setup guide
├── 📋 REPOSITORY_STRATEGY.md              # Repository organization strategy
│
├── 🚀 bootstrap/                          # Initial cluster setup (Phase 1-3)
│   ├── namespaces.yaml                    # Core namespaces (argocd, crossplane-system)
│   ├── argocd/
│   │   └── argocd-install.yaml           # ArgoCD Helm release + configuration
│   └── crossplane/
│       ├── crossplane-install.yaml       # Crossplane core installation
│       ├── provider-installs.yaml        # Helm & Kubernetes providers  
│       └── provider-rbac.yaml            # RBAC for Crossplane providers
│
├── 🏗️ infrastructure/                     # Infrastructure as Code (Phase 4-5)
│   ├── crossplane/                       # Crossplane definitions
│   │   ├── xrds/                        # Custom Resource Definitions (APIs)
│   │   │   ├── ingress-xrd.yaml         # IngressStack API definition
│   │   │   ├── observability-xrd.yaml   # ObservabilityStack API definition
│   │   │   └── argocd-app-xrd.yaml      # ArgoApplication API definition
│   │   ├── compositions/                 # How to create infrastructure
│   │   │   ├── ingress-composition.yaml  # MetalLB + nginx-ingress pattern
│   │   │   ├── observability-composition.yaml # Prometheus + Grafana + Loki
│   │   │   └── argocd-app-composition.yaml     # ArgoCD application factory
│   │   └── providers/
│   │       └── provider-config/         # Provider configurations
│   │           ├── helm-provider-config.yaml    # Helm provider setup
│   │           └── k8s-provider-config.yaml     # Kubernetes provider setup
│   │
│   └── platform/                        # Platform service claims (What you want)
│       ├── argocd/
│       │   └── workload-applications-claim.yaml # Creates ArgoCD app via Crossplane
│       ├── ingress/
│       │   └── ingress-stack-claim.yaml         # Requests ingress infrastructure
│       ├── observability/
│       │   └── observability-stack-claim.yaml   # Requests monitoring stack
│       ├── backup/
│       │   └── velero-release.yaml             # Backup solution via Helm
│       └── storage/
│           └── nfs-csi-setup.yaml              # NFS storage driver + StorageClass
│
├── 🔄 argocd-apps/                        # ArgoCD Applications (Phase 6)
│   ├── app-of-apps.yaml                  # Root app that manages all other apps
│   ├── infrastructure-apps.yaml          # Manages platform services
│   └── application-apps.yaml             # Manages workload applications
│
├── 🚀 applications/                       # Application workloads
│   └── workloads/
│       └── n8n/
│           └── n8n-release.yaml          # n8n workflow automation via Helm
│
└── 🔐 secrets/                           # Secret management
    └── external-secrets/
        └── external-secrets-operator.yaml # External secrets integration
```

## 🔄 How ArgoCD & Crossplane Work Together

### **The Flow: Git → ArgoCD → Crossplane → Infrastructure**

#### **1. GitOps Layer (ArgoCD)**
**Purpose:** Watches Git repo and syncs desired state to cluster

- **`app-of-apps.yaml`** - The orchestrator that manages all other ArgoCD applications
- **`infrastructure-apps.yaml`** - Syncs platform infrastructure from `infrastructure/platform/`
- **`application-apps.yaml`** - Syncs workloads from `applications/`

**ArgoCD monitors Git changes and ensures cluster matches repository state**

#### **2. Infrastructure Abstraction Layer (Crossplane)**
**Purpose:** Takes high-level claims and provisions actual infrastructure

- **Claims** (in `infrastructure/platform/`) - "I want an ingress stack"
- **XRDs** (in `infrastructure/crossplane/xrds/`) - Define the APIs for claims
- **Compositions** (in `infrastructure/crossplane/compositions/`) - Define HOW to fulfill claims
- **Managed Resources** - Actual Kubernetes objects, Helm releases, etc.

### **Example: Requesting Monitoring Stack**

```
1. 📝 You edit: infrastructure/platform/observability/observability-stack-claim.yaml
2. 🔄 Git commit/push: Change goes to repository  
3. 👁️ ArgoCD detects: Sees Git diff, syncs ObservabilityStack claim to cluster
4. ⚡ Crossplane processes: Uses observability-composition.yaml
5. 🏗️ Crossplane creates:
   - Namespace: monitoring
   - Helm Release: kube-prometheus-stack  
   - Helm Release: loki-stack
   - ConfigMaps, Secrets, etc.
6. ✅ Result: Full monitoring stack running
```

## 🚀 Quick Start Guide

### **Prerequisites**
- 3-node Kubernetes cluster (Talos HA with schedulable masters)
- MetalLB IP range: `10.20.0.81-10.20.0.90` 
- NFS server: `10.20.0.10` with `/volume1/kubernetes` share
- `kubectl` configured for cluster access

### **1. Clone & Configure**
```bash
git clone https://github.com/jamilshaikh07/homelab-gitops.git
cd homelab-gitops

# Update repository URLs in argocd-apps/ files
sed -i 's/jamilshaikh07/YOUR_USERNAME/g' argocd-apps/*.yaml
```

### **2. Deploy Bootstrap (ArgoCD + Crossplane)**
```bash
# Create namespaces and install core components
kubectl apply -f bootstrap/namespaces.yaml
kubectl apply -f bootstrap/crossplane/
kubectl apply -f bootstrap/argocd/

# Wait for ArgoCD to be ready
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### **3. Get ArgoCD Admin Password**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### **4. Configure Git Repository Access**
```bash
# Create repository secret for private repos
kubectl create secret generic github-repo-secret \
  --from-literal=type=git \
  --from-literal=url=https://github.com/jamilshaikh07/homelab-gitops.git \
  --from-literal=username=jamilshaikh07 \
  --from-literal=password=YOUR_GITHUB_PAT \
  -n argocd

kubectl label secret github-repo-secret argocd.argoproj.io/secret-type=repository -n argocd
```

### **5. Deploy GitOps Applications**
```bash
# Deploy the app-of-apps (this manages everything else)
kubectl apply -f argocd-apps/app-of-apps.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080 (admin / password from step 3)
```

## 🔧 Technology Stack Details

### **Core Platform**
| Component | Purpose | Configuration |
|-----------|---------|---------------|
| **Talos Linux** | Immutable OS for K8s | 3-node HA cluster, schedulable masters |
| **Crossplane** | Infrastructure orchestration | Helm + Kubernetes providers |
| **ArgoCD** | GitOps continuous deployment | App-of-apps pattern, auto-sync enabled |

### **Infrastructure Services**
| Service | Implementation | Configuration File |
|---------|----------------|-------------------|
| **Load Balancer** | MetalLB | `ingress-composition.yaml` |
| **Ingress** | nginx-ingress | `ingress-stack-claim.yaml` |
| **Storage** | NFS CSI Driver | `nfs-csi-setup.yaml` |
| **Monitoring** | Prometheus + Grafana + Loki | `observability-composition.yaml` |
| **Backup** | Velero | `velero-release.yaml` |
| **Secrets** | External Secrets Operator | `external-secrets-operator.yaml` |

### **Network Configuration**
- **MetalLB Pool:** `10.20.0.81-10.20.0.90`
- **NFS Server:** `10.20.0.10:/volume1/kubernetes`
- **Ingress Controller:** nginx with LoadBalancer type
- **TLS:** cert-manager for automatic certificate management

## 📊 Monitoring & Observability

### **Prometheus Stack Features**
- **Metrics Collection:** All platform components monitored
- **Custom Dashboards:** Crossplane, ArgoCD, application metrics
- **Alerting:** Platform health, resource utilization, GitOps failures
- **Storage:** Persistent volumes with NFS backend

### **Grafana Dashboards**
- Infrastructure overview and resource utilization
- ArgoCD application sync status and history
- Crossplane resource provisioning metrics
- Application performance and health monitoring

### **Loki Log Aggregation**
- Centralized logging for all platform components
- Integration with Grafana for unified observability
- Log-based alerting and troubleshooting capabilities

## 🔐 Security & Best Practices

### **Secret Management**
- **External Secrets Operator** for secret store integration
- **Never commit plaintext secrets** to Git repository
- **GitOps-friendly** encrypted secrets workflow
- **Automatic secret rotation** capabilities

### **RBAC & Access Control**
- **Crossplane provider permissions** properly configured
- **ArgoCD RBAC** for team-based access control
- **Namespace isolation** for workloads
- **Service account** principle of least privilege

### **Network Security**
- **Private Git repository** access via tokens
- **TLS everywhere** with automatic certificate management
- **Network policies** for pod-to-pod communication
- **Ingress protection** with proper SSL/TLS termination

## 🔄 Backup & Disaster Recovery

### **Multi-Layer Backup Strategy**
1. **Git Repository:** Primary source of truth protection
2. **Velero:** Kubernetes resources and persistent volume backups
3. **NAS-Level:** Storage system snapshots and replication
4. **Application Data:** Database dumps and application-specific backups

### **Recovery Procedures**
- **Complete cluster recovery** from Velero backups
- **GitOps state restoration** from Git repository
- **Application data recovery** from persistent volume snapshots
- **Configuration drift remediation** via ArgoCD sync

## 🛠️ Operational Workflows

### **Adding New Infrastructure**
1. **Create/update claim** in `infrastructure/platform/`
2. **Modify composition** if new patterns needed
3. **Git commit/push** - ArgoCD automatically deploys
4. **Monitor ArgoCD UI** for sync status

### **Deploying New Applications**
1. **Add Helm release** to `applications/workloads/`
2. **Update application-apps** if needed
3. **Git commit/push** - automatic deployment
4. **Verify in ArgoCD** and application dashboards

### **Troubleshooting Common Issues**
- **ArgoCD sync failures:** Check repository access and resource validation
- **Crossplane resource stuck:** Verify provider permissions and resource dependencies
- **Application deployment issues:** Check Helm values and resource quotas

## 📚 Additional Documentation

- **[Setup Guide](GITOPS_SETUP_GUIDE.md):** Comprehensive step-by-step installation
- **[Configuration Reference](CONFIGURATION.md):** All customizable parameters and options
- **[Disaster Recovery](DISASTER_RECOVERY.md):** Complete backup and recovery procedures
- **[Repository Strategy](REPOSITORY_STRATEGY.md):** Git workflow and organization patterns

## 🤝 Contributing & Customization

### **Extending the Platform**
1. **Add new XRDs** for custom infrastructure patterns
2. **Create compositions** for complex multi-component stacks  
3. **Integrate new providers** for cloud or external services
4. **Add monitoring dashboards** for custom applications

### **Best Practices for Changes**
- Test changes in separate branch/cluster first
- Update documentation with any configuration changes
- Follow GitOps principles - everything through Git
- Use proper commit messages for tracking changes

## ⚡ What Makes This Special

### **True GitOps Experience**
- **Everything in Git:** Infrastructure, applications, and configurations
- **Automatic synchronization:** Push to Git, see changes in cluster
- **Rollback capability:** Git revert = infrastructure rollback
- **Change tracking:** Full audit trail of all modifications

### **Production-Ready Platform**
- **High availability:** 3-node cluster with proper redundancy
- **Monitoring & alerting:** Complete observability stack included
- **Backup & recovery:** Multi-layer protection strategy
- **Security:** Proper RBAC, secret management, and network policies

### **Developer-Friendly**
- **Self-service infrastructure:** Developers can request resources via Git
- **Consistent environments:** Same GitOps process for all environments
- **Easy troubleshooting:** Centralized logging and monitoring
- **Rapid deployment:** Minutes from Git commit to running application

---

🏠 **Ready for your homelab?** This platform provides enterprise-grade GitOps workflows in a homelab-friendly package. From infrastructure provisioning to application deployment, everything is automated, monitored, and recoverable.

**Next Steps:** Follow the [Setup Guide](GITOPS_SETUP_GUIDE.md) for detailed deployment instructions!