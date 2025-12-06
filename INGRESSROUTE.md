# IngressRoute and Certificate Support

This Helm chart now supports Traefik IngressRoute with automatic certificate management via cert-manager.

## Features

- **HTTP/HTTPS IngressRoute**: Automatic TLS certificate provisioning
- **HTTP to HTTPS Redirect**: Optional automatic redirect middleware
- **TCP IngressRoute**: Support for TCP-based services (databases, custom protocols)
- **Custom Middlewares**: Easy integration with Traefik middlewares
- **Path-based Routing**: Optional path prefix routing

## Prerequisites

1. **Traefik** installed as ingress controller
2. **cert-manager** installed for certificate management
3. **ClusterIssuer** configured (e.g., Let's Encrypt)

## HTTP/HTTPS IngressRoute

### Basic Configuration

```yaml
ingressRoute:
  enabled: true
  host: api.example.com
  httpsRedirect: true
  certIssuer: letsencrypt
```

This creates:
- Certificate resource for TLS
- HTTP IngressRoute with redirect middleware
- HTTPS IngressRoute with TLS

### With Path Prefix

```yaml
ingressRoute:
  enabled: true
  host: api.example.com
  path: "/api"  # Routes only /api/* traffic
  httpsRedirect: true
  certIssuer: letsencrypt
```

### With Custom Middlewares

```yaml
ingressRoute:
  enabled: true
  host: api.example.com
  httpsRedirect: true
  certIssuer: letsencrypt
  middlewares:
    - auth-middleware
    - rate-limit
    - cors-headers
```

### Using Issuer Instead of ClusterIssuer

```yaml
ingressRoute:
  enabled: true
  host: api.example.com
  certIssuer: my-issuer
  certIssuerKind: Issuer  # Default is ClusterIssuer
```

## TCP IngressRoute

For TCP-based services like databases:

### Basic TCP (No TLS)

```yaml
ingressRouteTCP:
  enabled: true
  host: db.example.com
  entryPoints:
    - tcp
  tls:
    enabled: false
```

### TCP with TLS Termination

```yaml
ingressRouteTCP:
  enabled: true
  host: db.example.com
  entryPoints:
    - tcp-tls
  tls:
    enabled: true
    certIssuer: letsencrypt
    passthrough: false
```

### TCP with TLS Passthrough

For services that handle TLS themselves (MongoDB with TLS, PostgreSQL with SSL):

```yaml
ingressRouteTCP:
  enabled: true
  host: mongodb.example.com
  entryPoints:
    - tcp-tls
  tls:
    enabled: true
    certIssuer: letsencrypt
    passthrough: true
```

## Complete Examples

### Web Application

```yaml
replicaCount: 2

image:
  repository: myapp/frontend
  tag: "1.0.0"

service:
  type: ClusterIP
  port: 80

ingressRoute:
  enabled: true
  host: app.example.com
  httpsRedirect: true
  certIssuer: letsencrypt
  middlewares:
    - compress
    - security-headers

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### API Service with Path Routing

```yaml
image:
  repository: myapp/api
  tag: "2.0.0"

service:
  port: 8080

ingressRoute:
  enabled: true
  host: api.example.com
  path: "/v2"
  httpsRedirect: true
  certIssuer: letsencrypt
  middlewares:
    - api-auth
    - rate-limit-api

probes:
  livenessProbe:
    httpGet:
      path: /health
      port: 8080
  readinessProbe:
    httpGet:
      path: /ready
      port: 8080
```

### Database Service (TCP)

```yaml
image:
  repository: postgres
  tag: "15"

service:
  type: ClusterIP
  port: 5432

ingressRouteTCP:
  enabled: true
  host: postgres.example.com
  entryPoints:
    - postgres-tcp
  tls:
    enabled: true
    certIssuer: letsencrypt
    passthrough: false
```

## Traefik Configuration Requirements

### HTTP/HTTPS EntryPoints

Your Traefik must have these entryPoints configured:

```yaml
# Traefik values.yaml or static configuration
ports:
  web:
    port: 80
    expose: true
  websecure:
    port: 443
    expose: true
    tls:
      enabled: true
```

### TCP EntryPoints

For TCP IngressRoute, configure custom entryPoints:

```yaml
# Traefik values.yaml
ports:
  tcp:
    port: 9000
    expose: true
  tcp-tls:
    port: 9443
    expose: true
    tls:
      enabled: true
```

## cert-manager Configuration

### ClusterIssuer Example (Let's Encrypt)

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
    - http01:
        ingress:
          class: traefik
```

## Troubleshooting

### Certificate Not Issued

Check cert-manager logs:
```bash
kubectl logs -n cert-manager deploy/cert-manager
kubectl describe certificate <release-name>-tls
```

### IngressRoute Not Working

Check Traefik logs:
```bash
kubectl logs -n traefik deploy/traefik
kubectl describe ingressroute <release-name>
```

### HTTP Redirect Loop

Ensure `httpsRedirect: true` is set and Traefik is properly configured with both `web` and `websecure` entryPoints.

## Migration from Standard Ingress

If you're migrating from the standard `ingress` configuration:

**Before:**
```yaml
ingress:
  enabled: true
  className: traefik
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com
```

**After:**
```yaml
ingressRoute:
  enabled: true
  host: app.example.com
  httpsRedirect: true
  certIssuer: letsencrypt
```

The IngressRoute approach provides:
- Automatic certificate management
- Built-in HTTP to HTTPS redirect
- Better Traefik middleware integration
- Simpler configuration
