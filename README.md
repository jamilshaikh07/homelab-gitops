# Homelab GitOps

This repository manages your homelab cluster via Argo CD and Crossplane. Argo CD provides the UI and sync engine; Crossplane owns resource creation inside the cluster.

## App of Apps

- Root app: `argocd/app-of-apps.yaml` points to `apps/` which contains child apps.
- Child apps:
  - `crossplane-provider-kubernetes-app.yaml` installs and configures `provider-kubernetes` so Crossplane can apply in-cluster Kubernetes objects.
  - `metallb-config-app.yaml` applies MetalLB configuration (via Crossplane Objects) for the service IP pool.

## Crossplane provider-kubernetes

- Installed from: `crossplane/provider-kubernetes/provider.yaml`
- ProviderConfig: `crossplane/provider-kubernetes/providerconfig.yaml` uses `InjectedIdentity`, so Crossplane uses its in-cluster ServiceAccount to talk to the API.

## MetalLB configuration

Applied via Crossplane `Object` resources in `metallb/`:

- `metallb-ipaddresspool.yaml`: creates `IPAddressPool` named `homelab-pool` in `metallb-system` with range `10.20.0.81-10.20.0.99`.
- `metallb-l2advertisement.yaml`: creates `L2Advertisement` `homelab-l2adv` advertising `homelab-pool`.

Result: LoadBalancer Services will receive IPs from `10.20.0.81-10.20.0.99`.

## Sync order

- Root app wave -1
- Crossplane provider app wave 0
- MetalLB config app wave 1

## Verify

- Argo CD: ensure all apps are Healthy/Synced.
- MetalLB:
  - `kubectl -n metallb-system get ipaddresspools.metallb.io`
  - `kubectl -n metallb-system get l2advertisements.metallb.io`
  - Create a `Service` type `LoadBalancer` and check it gets an IP in the reserved range.

## Notes

- Requires MetalLB installed in `metallb-system` namespace.
- Crossplane must be installed and running in `crossplane-system`.
