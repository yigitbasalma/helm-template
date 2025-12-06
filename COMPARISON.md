# Ingress vs IngressRoute Comparison

## Standard Ingress vs Traefik IngressRoute

### Standard Ingress (Old Way)

```yaml
ingress:
  enabled: true
  className: traefik
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
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

**Limitations:**
- Manual certificate secret management
- No built-in HTTP→HTTPS redirect
- Limited middleware support
- Generic Ingress API (not Traefik-specific)
- Requires annotations for Traefik features

### Traefik IngressRoute (New Way)

```yaml
ingressRoute:
  enabled: true
  host: app.example.com
  httpsRedirect: true
  certIssuer: letsencrypt
```

**Benefits:**
- ✅ Automatic certificate creation
- ✅ Built-in HTTP→HTTPS redirect
- ✅ Native Traefik middleware support
- ✅ Simpler configuration
- ✅ Better Traefik integration
- ✅ Type-safe Traefik features

## Feature Comparison

| Feature | Standard Ingress | IngressRoute |
|---------|-----------------|--------------|
| Certificate Management | Manual | Automatic |
| HTTP Redirect | Manual middleware | Built-in |
| Middleware Support | Via annotations | Native |
| Path Routing | ✅ | ✅ |
| TCP Support | ❌ | ✅ |
| TLS Passthrough | ❌ | ✅ |
| Configuration Lines | ~20 | ~5 |
| Traefik-Specific | ❌ | ✅ |

## When to Use Each

### Use Standard Ingress When:
- You need multi-ingress-controller support
- You're using a non-Traefik ingress controller
- You need maximum portability
- You have existing Ingress resources

### Use IngressRoute When:
- You're using Traefik as ingress controller
- You want automatic certificate management
- You need TCP routing
- You want simpler configuration
- You need advanced Traefik features

## Migration Example

### Before (Standard Ingress)

```yaml
# values.yaml
ingress:
  enabled: true
  className: traefik
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
    traefik.ingress.kubernetes.io/router.middlewares: default-redirect-https@kubernetescrd
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: api-tls
      hosts:
        - api.example.com

# Separate middleware resource needed
---
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: redirect-https
spec:
  redirectScheme:
    scheme: https
    permanent: true
```

### After (IngressRoute)

```yaml
# values.yaml
ingressRoute:
  enabled: true
  host: api.example.com
  httpsRedirect: true
  certIssuer: letsencrypt
```

**Result:**
- 15 lines → 5 lines
- No separate middleware needed
- Automatic certificate creation
- Built-in redirect

## Advanced Features Comparison

### Custom Middlewares

**Standard Ingress:**
```yaml
ingress:
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: |
      default-auth@kubernetescrd,
      default-rate-limit@kubernetescrd
```

**IngressRoute:**
```yaml
ingressRoute:
  middlewares:
    - auth
    - rate-limit
```

### Path-Based Routing

**Standard Ingress:**
```yaml
ingress:
  hosts:
    - host: api.example.com
      paths:
        - path: /v1
          pathType: Prefix
        - path: /v2
          pathType: Prefix
```

**IngressRoute:**
```yaml
ingressRoute:
  host: api.example.com
  path: "/v1"  # Single path per IngressRoute
```

*Note: For multiple paths, create multiple IngressRoute resources*

### TCP Services

**Standard Ingress:**
```
Not supported - requires separate TCP configuration
```

**IngressRoute:**
```yaml
ingressRouteTCP:
  enabled: true
  host: db.example.com
  entryPoints:
    - postgres-tcp
  tls:
    enabled: true
```

## Performance Considerations

### Standard Ingress
- Generic API requires translation
- Additional annotation parsing
- Potential delays in configuration updates

### IngressRoute
- Native Traefik resource
- Direct configuration
- Faster updates and changes
- Better performance for Traefik-specific features

## Recommendation

**For new deployments with Traefik:** Use IngressRoute
- Simpler configuration
- Better integration
- More features
- Easier maintenance

**For existing deployments:** Consider migration
- Evaluate benefits vs effort
- Can run both simultaneously
- Migrate incrementally
- Test thoroughly before switching

## Both Can Coexist

You can use both in the same cluster:

```yaml
# Use standard Ingress for some services
ingress:
  enabled: true
  hosts:
    - host: legacy.example.com

# Use IngressRoute for others
ingressRoute:
  enabled: true
  host: new.example.com
```

This allows gradual migration without disruption.
