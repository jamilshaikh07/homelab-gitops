# ArgoCD Configuration for External Proxy Setup

This document describes the ArgoCD configuration required when running behind an external proxy (NGINX Proxy Manager) that handles SSL termination.

## Architecture Overview

```
Internet (HTTPS) → NGINX Proxy Manager (10.20.0.127) → Kubernetes Ingress (HTTP) → ArgoCD Server
```

- **External Proxy**: NGINX Proxy Manager at `10.20.0.127`
- **Domain**: `argocd.devopsowl.com`
- **SSL**: Handled by NGINX Proxy Manager with Let's Encrypt DNS01 challenge
- **Certificate**: Wildcard certificate for `*.devopsowl.com`

## Configuration Steps

### 1. ArgoCD Server Configuration

ArgoCD needs to be configured to run in insecure mode since SSL termination is handled upstream:

```bash
# Configure ArgoCD server to accept HTTP connections
kubectl patch configmap argocd-cmd-params-cm -n argocd --patch='
data:
  server.insecure: "true"
'

# Restart ArgoCD server to apply configuration
kubectl rollout restart deployment/argocd-server -n argocd

# Verify the server is running
kubectl get pods -n argocd | grep server
```

### 2. Ingress Configuration

The ingress is configured to work with external SSL termination:

```yaml
# manifests/homelab-services/argocd-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-ingress
  namespace: argocd
  annotations:
    # Disable SSL redirect since external proxy handles SSL
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    # Use HTTP backend since ArgoCD runs in insecure mode
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    # Forward proper headers for HTTPS detection
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Forwarded-Proto: https";
      more_set_headers "X-Forwarded-For: $proxy_add_x_forwarded_for";
spec:
  ingressClassName: nginx
  rules:
    - host: argocd.devopsowl.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80  # HTTP port since SSL is terminated externally
```

## Verification Commands

### Check ArgoCD Configuration

```bash
# Verify ArgoCD server configuration
kubectl get configmap argocd-cmd-params-cm -n argocd -o yaml

# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Verify ingress is created
kubectl get ingress -n argocd
```

### Test Connectivity

```bash
# Test external access (should return 200 OK)
curl -v https://argocd.devopsowl.com

# Test internal service (should return ArgoCD response)
kubectl port-forward -n argocd svc/argocd-server 8080:80
curl http://localhost:8080
```

## Troubleshooting

### Common Issues

1. **Redirect Loop**: If you see 307 redirects, ensure:
   - `server.insecure: "true"` is set in ArgoCD configuration
   - Ingress has `ssl-redirect: "false"`
   - External proxy is forwarding to HTTP (not HTTPS)

2. **404 Not Found**: Check that:
   - Ingress is created and has the correct service name
   - ArgoCD server service is running on port 80
   - NGINX Ingress Controller is deployed and healthy

3. **SSL Certificate Issues**: Verify:
   - External proxy has valid certificate for `*.devopsowl.com`
   - DNS resolves `argocd.devopsowl.com` to `10.20.0.127`

### Debug Commands

```bash
# Check ArgoCD applications
kubectl get applications -n argocd

# Check NGINX Ingress Controller
kubectl get pods -n ingress-nginx

# Check service endpoints
kubectl get endpoints -n argocd argocd-server

# View ingress details
kubectl describe ingress argocd-ingress -n argocd
```

## Access Information

- **ArgoCD UI**: https://argocd.devopsowl.com
- **Default Credentials**: 
  - Username: `admin`
  - Password: Get with `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

## Related Services

This setup also includes ingress configuration for:
- **Grafana**: https://grafana.devopsowl.com
- **Prometheus**: https://prometheus.devopsowl.com

All services use the same external proxy pattern with SSL termination at NGINX Proxy Manager.