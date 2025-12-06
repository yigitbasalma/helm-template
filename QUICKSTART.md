# Quick Start Guide - IngressRoute & Certificates

## 1. Basic Web Application with HTTPS

```yaml
# values.yaml
image:
  repository: myapp/web
  tag: "1.0.0"

service:
  port: 80

ingressRoute:
  enabled: true
  host: myapp.example.com
  httpsRedirect: true
  certIssuer: letsencrypt
```

Deploy:
```bash
helm install myapp . -f values.yaml
```

This creates:
- ✅ Certificate from Let's Encrypt
- ✅ HTTP → HTTPS redirect
- ✅ HTTPS IngressRoute with TLS

## 2. API with Path-Based Routing

```yaml
# values-api.yaml
service:
  port: 8080

ingressRoute:
  enabled: true
  host: api.example.com
  path: "/v1"  # Only routes /v1/* traffic
  httpsRedirect: true
  certIssuer: letsencrypt
```

## 3. With Authentication Middleware

```yaml
ingressRoute:
  enabled: true
  host: admin.example.com
  httpsRedirect: true
  certIssuer: letsencrypt
  middlewares:
    - oauth2-proxy  # Your Traefik middleware name
```

## 4. Database Service (TCP)

```yaml
# values-db.yaml
service:
  port: 5432

ingressRouteTCP:
  enabled: true
  host: db.example.com
  entryPoints:
    - postgres-tcp  # Must match Traefik config
  tls:
    enabled: true
    certIssuer: letsencrypt
```

## 5. Multiple Services (HTTP + TCP)

```yaml
service:
  port: 8080

# Web interface
ingressRoute:
  enabled: true
  host: app.example.com
  httpsRedirect: true
  certIssuer: letsencrypt

# Admin TCP interface
ingressRouteTCP:
  enabled: true
  host: admin-tcp.example.com
  entryPoints:
    - admin-tcp
  tls:
    enabled: true
    certIssuer: letsencrypt
```

## Common Patterns

### Staging Environment

```yaml
ingressRoute:
  enabled: true
  host: staging.myapp.com
  certIssuer: letsencrypt-staging  # Use staging for testing
  httpsRedirect: true
```

### Production with Rate Limiting

```yaml
ingressRoute:
  enabled: true
  host: api.myapp.com
  certIssuer: letsencrypt
  httpsRedirect: true
  middlewares:
    - rate-limit-100
    - compress
    - security-headers
```

### Internal Service (No TLS)

```yaml
ingressRoute:
  enabled: true
  host: internal.myapp.local
  httpsRedirect: false  # No HTTPS redirect
  certIssuer: internal-ca
```

## Testing

### Dry Run
```bash
helm install myapp . --dry-run --debug
```

### Template Validation
```bash
helm template myapp . -f values.yaml | kubectl apply --dry-run=client -f -
```

### Check Certificate Status
```bash
kubectl get certificate
kubectl describe certificate myapp-tls
```

### Check IngressRoute
```bash
kubectl get ingressroute
kubectl describe ingressroute myapp
```

## Troubleshooting

### Certificate Pending
```bash
# Check cert-manager logs
kubectl logs -n cert-manager deploy/cert-manager

# Check certificate status
kubectl describe certificate <name>-tls

# Check certificate request
kubectl get certificaterequest
```

### IngressRoute Not Working
```bash
# Check Traefik logs
kubectl logs -n traefik deploy/traefik

# Verify service exists
kubectl get svc

# Check IngressRoute
kubectl describe ingressroute <name>
```

### 404 Not Found
- Verify service port matches `service.port` in values
- Check if path prefix is correct
- Ensure Traefik can reach the service

### Redirect Loop
- Set `httpsRedirect: true` in values
- Verify Traefik has both `web` and `websecure` entryPoints
- Check if middleware is correctly configured
