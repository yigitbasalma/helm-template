# Base Helm Template

A comprehensive Helm template for Kubernetes applications with support for multiple ConfigMaps, IngressRoutes, and advanced deployment features.

## Features

- ✅ **Multiple ConfigMaps Support** - Create multiple ConfigMaps with custom names and labels
- ✅ **IngressRoute Support** - Traefik IngressRoute with automatic TLS certificates
- ✅ **TCP IngressRoute** - Support for TCP services (databases, custom protocols)
- ✅ **CronJobs** - Scheduled job support
- ✅ **Autoscaling** - HPA with CPU and memory metrics
- ✅ **Probes** - Liveness and readiness probes
- ✅ **PVC Support** - Persistent volume claims
- ✅ **Service Account** - Custom service accounts with annotations

## Quick Start

### 1. Basic Deployment

```bash
helm install myapp . --values values.yaml
```

### 2. With Custom Values

```bash
helm install myapp . --values values-example.yaml
```

### 3. Dry Run

```bash
helm template myapp . --values values.yaml --dry-run
```

## Configuration

### Multiple ConfigMaps

Create multiple ConfigMaps with custom names, labels, and annotations:

```yaml
multipleConfigMaps:
  - name: app-config
    labels:
      app.kubernetes.io/component: config
    annotations:
      description: "Application configuration"
    data:
      application.properties: |
        server.port=8080
        spring.datasource.url=jdbc:mysql://db:3306/myapp
      
      database.properties: |
        spring.datasource.hikari.maximum-pool-size=20

  - name: nginx-config
    labels:
      app.kubernetes.io/component: proxy
    data:
      nginx.conf: |
        events { worker_connections 1024; }
        http {
          upstream backend { server backend:8080; }
          server {
            listen 80;
            location / { proxy_pass http://backend; }
          }
        }
```

**Generated ConfigMap Names**: `{release-name}-{config-name}`

Example: Release `myapp` with config `app-config` creates `myapp-app-config`

### IngressRoute (Traefik)

```yaml
ingressRoute:
  enabled: true
  host: api.example.com
  httpsRedirect: true
  certIssuer: letsencrypt
  middlewares:
    - auth-middleware
    - rate-limit
```

### Environment Variables

```yaml
environments:
  - name: APP_ENV
    value: production
  - name: LOG_LEVEL
    value: info

environmentsFrom:
  - configMapRef:
      name: myapp-app-config
  - secretRef:
      name: app-secrets
```

### Probes

```yaml
probes:
  livenessProbe:
    httpGet:
      path: /health
      port: 8080
    initialDelaySeconds: 30
  readinessProbe:
    httpGet:
      path: /ready
      port: 8080
    initialDelaySeconds: 5
```

### Autoscaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

### CronJobs

```yaml
cronJobs:
  - name: cleanup-temp
    schedule: "0 2 * * *"
    image: "busybox:1.40"
    command: ["/bin/sh", "-c"]
    args: ["find /tmp -name '*.tmp' -delete"]
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"
```

## Documentation

- **[CONFIGMAPS.md](CONFIGMAPS.md)** - Detailed ConfigMaps documentation
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide
- **[INGRESSROUTE.md](INGRESSROUTE.md)** - IngressRoute configuration
- **[COMPARISON.md](COMPARISON.md)** - Feature comparison
- **[values-example.yaml](values-example.yaml)** - Complete example configuration

## Examples

### Spring Boot Application

```yaml
image:
  repository: myapp/api
  tag: "1.0.0"

service:
  port: 8080

multipleConfigMaps:
  - name: spring-config
    data:
      application.yml: |
        server:
          port: 8080
        spring:
          datasource:
            url: jdbc:postgresql://postgres:5432/mydb

probes:
  livenessProbe:
    httpGet:
      path: /actuator/health
      port: 8080
  readinessProbe:
    httpGet:
      path: /actuator/health/readiness
      port: 8080

ingressRoute:
  enabled: true
  host: api.example.com
  certIssuer: letsencrypt
```

### Nginx Reverse Proxy

```yaml
image:
  repository: nginx
  tag: "1.21"

multipleConfigMaps:
  - name: nginx-config
    data:
      nginx.conf: |
        events { worker_connections 1024; }
        http {
          upstream backend { server backend-service:8080; }
          server {
            listen 80;
            location / { proxy_pass http://backend; }
          }
        }

volumes:
  - name: nginx-config
    configMap:
      name: "{{ include \"bss.fullname\" . }}-nginx-config"

volumeMounts:
  - name: nginx-config
    mountPath: /etc/nginx/nginx.conf
    subPath: nginx.conf
```

## Migration Guide

### From Single ConfigMap

**Before:**
```yaml
configMaps:
  application.properties: |
    server.port=8080
  logback.xml: |
    <configuration>...</configuration>
```

**After:**
```yaml
multipleConfigMaps:
  - name: app-config
    data:
      application.properties: |
        server.port=8080
  - name: logging-config
    data:
      logback.xml: |
        <configuration>...</configuration>
```

## Best Practices

1. **Organize by Purpose**: Group related configs into separate ConfigMaps
2. **Use Descriptive Names**: `database-config`, `logging-config`, `nginx-config`
3. **Add Labels**: Use labels for better organization and selection
4. **Document with Annotations**: Add descriptions and metadata
5. **Environment Separation**: Use different values files for different environments

## Troubleshooting

### Check Generated Resources

```bash
# View all generated resources
helm template myapp . --values values.yaml

# Check specific ConfigMaps
helm template myapp . --values values.yaml | grep -A 20 "kind: ConfigMap"

# Validate YAML
helm template myapp . --values values.yaml --dry-run
```

### Debug ConfigMaps

```bash
# List ConfigMaps
kubectl get configmaps

# Check ConfigMap content
kubectl get configmap myapp-app-config -o yaml

# Describe ConfigMap
kubectl describe configmap myapp-app-config
```

## Requirements

- Helm 3.x
- Kubernetes 1.19+
- Traefik (for IngressRoute)
- cert-manager (for automatic TLS certificates)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm template` and `helm lint`
5. Submit a pull request

## License

MIT License

## Support

For issues and questions:
- Check the documentation files
- Use `helm template` for debugging
- Validate YAML syntax
- Check Kubernetes events and logs