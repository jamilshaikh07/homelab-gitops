# Disabled Applications

This directory contains ArgoCD Application manifests that are temporarily disabled.

## Purpose

Applications in this directory are **not** monitored by the App of Apps pattern and will **not** be deployed to the cluster.

## Currently Disabled

- `nginx-ingress.yaml` - NGINX Ingress Controller (disabled per user request)

## Re-enabling Applications

To re-enable any application:

1. Move the YAML file from `apps-disabled/` back to `apps/`
2. Commit and push the changes
3. ArgoCD will automatically detect and deploy the application

Example:
```bash
# Re-enable nginx-ingress
mv apps-disabled/nginx-ingress.yaml apps/
git add apps/nginx-ingress.yaml
git commit -m "Re-enable nginx-ingress"
git push
```

## Alternative: Temporary Disable

If you want to temporarily disable an application without moving files, you can also:

1. Delete the application from ArgoCD UI or CLI
2. Keep the manifest file in the `apps/` directory but add `.disabled` extension
3. The App of Apps will ignore files that don't end in `.yaml`