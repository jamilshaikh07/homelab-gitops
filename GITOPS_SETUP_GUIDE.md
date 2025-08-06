# Modern GitOps Platform Setup Guide
## Crossplane + ArgoCD for Infrastructure and Application Management

This guide provides a comprehensive step-by-step approach to setting up a modern GitOps platform using Crossplane for infrastructure management and ArgoCD for GitOps automation.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Folder Structure](#folder-structure)
4. [Phase 1: Bootstrap Setup](#phase-1-bootstrap-setup)
5. [Phase 2: Crossplane Installation](#phase-2-crossplane-installation)
6. [Phase 3: ArgoCD Installation](#phase-3-argocd-installation)
7. [Phase 4: Provider Configuration](#phase-4-provider-configuration)
8. [Phase 5: Platform Services](#phase-5-platform-services)
9. [Phase 6: Application Deployment](#phase-6-application-deployment)
10. [Secrets Management](#secrets-management)
11. [Disaster Recovery Strategy](#disaster-recovery-strategy)
12. [Best Practices](#best-practices)
13. [Troubleshooting](#troubleshooting)

## Architecture Overview

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

## Prerequisites

- Kubernetes cluster (Talos Linux) with kubeconfig access
- `kubectl` configured and working
- `helm` CLI installed
- Git repository for storing manifests
- Basic understanding of Kubernetes, Helm, and GitOps concepts

## Folder Structure

The recommended folder structure follows GitOps best practices with clear separation of concerns:

```
gitops-platform/
├── README.md
├── bootstrap/
│   ├── argocd/
│   │   ├── namespace.yaml
│   │   ├── argocd-install.yaml
│   │   └── argocd-config.yaml
│   └── crossplane/
│       ├── namespace.yaml
│       ├── crossplane-install.yaml
│       └── provider-installs.yaml
├── infrastructure/
│   ├── crossplane/
│   │   ├── providers/
│   │   │   ├── provider-helm.yaml
│   │   │   ├── provider-kubernetes.yaml
│   │   │   └── provider-config/
│   │   │       ├── helm-provider-config.yaml
│   │   │       └── k8s-provider-config.yaml
│   │   ├── compositions/
│   │   │   ├── observability-composition.yaml
│   │   │   ├── storage-composition.yaml
│   │   │   ├── ingress-composition.yaml
│   │   │   └── backup-composition.yaml
│   │   └── xrds/
│   │       ├── observability-xrd.yaml
│   │       ├── storage-xrd.yaml
│   │       ├── ingress-xrd.yaml
│   │       └── backup-xrd.yaml
│   └── platform/
│       ├── storage/
│       │   └── nfs-csi-claim.yaml
│       ├── backup/
│       │   └── velero-claim.yaml
│       ├── ingress/
│       │   ├── nginx-claim.yaml
│       │   ├── traefik-claim.yaml
│       │   └── metallb-claim.yaml
│       └── observability/
│           ├── prometheus-stack-claim.yaml
│           ├── loki-stack-claim.yaml
│           └── grafana-claim.yaml
├── applications/
│   ├── workloads/
│   │   ├── n8n/
│   │   │   ├── n8n-claim.yaml
│   │   │   └── postgres-claim.yaml
│   │   └── other-apps/
│   └── system/
│       └── cert-manager/
│           └── cert-manager-claim.yaml
├── argocd-apps/
│   ├── app-of-apps.yaml
│   ├── infrastructure-apps.yaml
│   ├── platform-apps.yaml
│   └── application-apps.yaml
└── secrets/
    ├── external-secrets/
    │   ├── external-secrets-operator.yaml
    │   └── secret-stores/
    └── sealed-secrets/
        └── sealed-secrets-controller.yaml
```

## Phase 1: Bootstrap Setup

### Step 1.1: Create Bootstrap Namespaces

First, let's create the necessary namespaces for our bootstrap components.

### Step 1.2: Install ArgoCD

ArgoCD will be our GitOps engine that watches the Git repository and applies changes to the cluster.

### Step 1.3: Install Crossplane

Crossplane will manage all our infrastructure components through compositions and custom resources.

## Phase 2: Crossplane Installation

### Step 2.1: Install Crossplane Core

### Step 2.2: Install Required Providers

We'll need the following providers:
- `provider-helm`: For managing Helm releases
- `provider-kubernetes`: For managing Kubernetes resources

### Step 2.3: Configure Provider Permissions

## Phase 3: ArgoCD Installation

### Step 3.1: Install ArgoCD

### Step 3.2: Configure ArgoCD

### Step 3.3: Setup App of Apps Pattern

## Phase 4: Provider Configuration

### Step 4.1: Configure Helm Provider

### Step 4.2: Configure Kubernetes Provider

## Phase 5: Platform Services

### Step 5.1: Storage (NFS CSI)

### Step 5.2: Backup (Velero)

### Step 5.3: Ingress Controllers

### Step 5.4: Observability Stack

## Phase 6: Application Deployment

### Step 6.1: System Applications

### Step 6.2: Workload Applications

## Secrets Management

### Option 1: External Secrets Operator (Recommended)

### Option 2: Sealed Secrets

### Option 3: ArgoCD Vault Plugin

## Disaster Recovery Strategy

### 1. Git Repository Backup

### 2. Cluster State Backup

### 3. Recovery Procedures

## Best Practices

### 1. Git Workflow

### 2. Resource Naming

### 3. Resource Organization

### 4. Security Considerations

### 5. Monitoring and Alerting

## Troubleshooting

### Common Issues

### Debugging Commands

### Recovery Procedures

---

This guide provides the foundation for a robust GitOps platform. Each phase should be implemented incrementally, with proper testing and validation before moving to the next phase.
