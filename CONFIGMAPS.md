# Multiple ConfigMaps Support

This Helm template supports creating multiple ConfigMaps with custom names, labels, and annotations.

## Features

- ✅ Create multiple ConfigMaps from a single values file
- ✅ Custom names for each ConfigMap
- ✅ Custom labels and annotations per ConfigMap
- ✅ Backward compatibility with legacy single ConfigMap
- ✅ Automatic naming with release prefix
- ✅ Support for any file type (properties, YAML, XML, scripts, etc.)

## Configuration Structure

```yaml
multipleConfigMaps:
  - name: config-name                    # Required: ConfigMap name suffix
    labels:                              # Optional: Additional labels
      app.kubernetes.io/component: config
      config-type: application
    annotations:                         # Optional: Annotations
      description: "Configuration description"
    data:                               # Required: ConfigMap data
      file1.properties: |
        key=value
      file2.yaml: |
        server:
          port: 8080
```

## Generated ConfigMap Names

ConfigMaps are created with the pattern: `{release-name}-{config-name}`

Example:
- Release name: `myapp`
- Config name: `database`
- Generated ConfigMap name: `myapp-database`

## Usage Examples

### 1. Application Configuration

```yaml
multipleConfigMaps:
  - name: app-config
    labels:
      app.kubernetes.io/component: config
    annotations:
      description: "Main application configuration"
    data:
      application.properties: |
        server.port=8080
        spring.datasource.url=jdbc:mysql://db:3306/myapp
        logging.level.com.myapp=INFO
      
      database.properties: |
        spring.datasource.hikari.maximum-pool-size=20
        spring.datasource.hikari.connection-timeout=20000
```

### 2. Logging Configuration

```yaml
multipleConfigMaps:
  - name: logging-config
    labels:
      app.kubernetes.io/component: logging
    data:
      logback.xml: |
        <configuration>
          <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
            <layout class="ch.qos.logback.classic.PatternLayout">
              <Pattern>%d{HH:mm:ss.SSS} [%t] %-5level %logger{36} - %msg%n</Pattern>
            </layout>
          </appender>
          <root level="info">
            <appender-ref ref="CONSOLE"/>
          </root>
        </configuration>
```

### 3. Nginx Configuration

```yaml
multipleConfigMaps:
  - name: nginx-config
    labels:
      app.kubernetes.io/component: proxy
    annotations:
      nginx.org/config: "true"
    data:
      nginx.conf: |
        events {
          worker_connections 1024;
        }
        http {
          upstream backend {
            server backend-service:8080;
          }
          server {
            listen 80;
            location / {
              proxy_pass http://backend;
            }
          }
        }
      
      mime.types: |
        types {
          text/html html htm shtml;
          text/css css;
          application/javascript js;
        }
```

### 4. Scripts Configuration

```yaml
multipleConfigMaps:
  - name: scripts-config
    labels:
      app.kubernetes.io/component: scripts
    data:
      init.sh: |
        #!/bin/bash
        echo "Initializing application..."
        mkdir -p /app/logs
        chmod +x /app/bin/*
      
      healthcheck.sh: |
        #!/bin/bash
        curl -f http://localhost:8080/health || exit 1
      
      cleanup.sh: |
        #!/bin/bash
        find /tmp -name "*.tmp" -delete
```

### 5. Multiple Environment Configurations

```yaml
multipleConfigMaps:
  - name: dev-config
    labels:
      environment: development
    data:
      application-dev.properties: |
        server.port=8080
        logging.level.root=DEBUG
        spring.profiles.active=dev
  
  - name: prod-config
    labels:
      environment: production
    data:
      application-prod.properties: |
        server.port=8080
        logging.level.root=WARN
        spring.profiles.active=prod
```

## Using ConfigMaps in Deployments

### Volume Mounts

```yaml
volumes:
  - name: app-config
    configMap:
      name: myapp-app-config
  - name: logging-config
    configMap:
      name: myapp-logging-config
  - name: scripts
    configMap:
      name: myapp-scripts-config
      defaultMode: 0755  # Make scripts executable

volumeMounts:
  - name: app-config
    mountPath: /app/config
  - name: logging-config
    mountPath: /app/config/logging
  - name: scripts
    mountPath: /app/scripts
```

### Environment Variables from ConfigMap

```yaml
environmentsFrom:
  - configMapRef:
      name: myapp-app-config
```

### Specific Files

```yaml
volumes:
  - name: nginx-config
    configMap:
      name: myapp-nginx-config
      items:
        - key: nginx.conf
          path: nginx.conf
        - key: mime.types
          path: mime.types

volumeMounts:
  - name: nginx-config
    mountPath: /etc/nginx/nginx.conf
    subPath: nginx.conf
  - name: nginx-config
    mountPath: /etc/nginx/mime.types
    subPath: mime.types
```

## Best Practices

### 1. Organize by Purpose

Group related configuration files into logical ConfigMaps:

```yaml
multipleConfigMaps:
  # Application settings
  - name: app-config
    data:
      application.properties: |
        # App config here
  
  # Database settings
  - name: db-config
    data:
      database.properties: |
        # DB config here
  
  # Logging settings
  - name: logging-config
    data:
      logback.xml: |
        # Logging config here
```

### 2. Use Descriptive Names

```yaml
multipleConfigMaps:
  # ✅ Good: Descriptive names
  - name: database-config
  - name: redis-config
  - name: monitoring-config
  
  # ❌ Avoid: Generic names
  - name: config1
  - name: data
  - name: files
```

### 3. Add Meaningful Labels

```yaml
multipleConfigMaps:
  - name: app-config
    labels:
      app.kubernetes.io/component: config
      config-type: application
      environment: production
      version: "1.0"
```

### 4. Use Annotations for Documentation

```yaml
multipleConfigMaps:
  - name: nginx-config
    annotations:
      description: "Nginx reverse proxy configuration"
      maintainer: "platform-team@company.com"
      config.kubernetes.io/version: "2.1"
      nginx.org/config: "true"
```

### 5. Separate by Environment

```yaml
# Development
multipleConfigMaps:
  - name: app-config
    labels:
      environment: dev
    data:
      application.properties: |
        logging.level.root=DEBUG

# Production  
multipleConfigMaps:
  - name: app-config
    labels:
      environment: prod
    data:
      application.properties: |
        logging.level.root=WARN
```

## Migration from Legacy ConfigMap

### Before (Legacy)

```yaml
configMaps:
  application.properties: |
    server.port=8080
  logback.xml: |
    <configuration>...</configuration>
```

### After (Multiple ConfigMaps)

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

## Common Use Cases

### 1. Spring Boot Application

```yaml
multipleConfigMaps:
  - name: spring-config
    data:
      application.yml: |
        server:
          port: 8080
        spring:
          datasource:
            url: jdbc:postgresql://postgres:5432/mydb
      
      application-prod.yml: |
        logging:
          level:
            com.myapp: WARN
```

### 2. Microservices Configuration

```yaml
multipleConfigMaps:
  - name: service-discovery
    data:
      consul.json: |
        {
          "datacenter": "dc1",
          "server": true,
          "bootstrap_expect": 3
        }
  
  - name: api-gateway
    data:
      gateway.yml: |
        routes:
          - id: user-service
            uri: http://user-service:8080
            predicates:
              - Path=/users/**
```

### 3. Database Configuration

```yaml
multipleConfigMaps:
  - name: postgres-config
    data:
      postgresql.conf: |
        max_connections = 100
        shared_buffers = 128MB
        effective_cache_size = 4GB
      
      pg_hba.conf: |
        local   all             all                                     trust
        host    all             all             127.0.0.1/32            md5
```

### 4. Monitoring Stack

```yaml
multipleConfigMaps:
  - name: prometheus-config
    data:
      prometheus.yml: |
        global:
          scrape_interval: 15s
        scrape_configs:
          - job_name: 'kubernetes-pods'
            kubernetes_sd_configs:
              - role: pod
  
  - name: grafana-config
    data:
      grafana.ini: |
        [server]
        http_port = 3000
        [security]
        admin_user = admin
```

## Troubleshooting

### ConfigMap Not Created

Check if the configuration is properly formatted:

```bash
# Validate YAML syntax
helm template myapp . --values values.yaml --dry-run

# Check generated ConfigMaps
helm template myapp . --values values.yaml | grep -A 20 "kind: ConfigMap"
```

### ConfigMap Name Issues

Verify the generated ConfigMap names:

```bash
# List ConfigMaps
kubectl get configmaps

# Check specific ConfigMap
kubectl describe configmap myapp-app-config
```

### Volume Mount Issues

Check if the ConfigMap exists and has the expected keys:

```bash
# Check ConfigMap data
kubectl get configmap myapp-app-config -o yaml

# Check pod volume mounts
kubectl describe pod <pod-name>
```

## Limitations

1. **Size Limit**: ConfigMaps have a 1MB size limit
2. **Binary Data**: Use Secrets for binary data instead of ConfigMaps
3. **Updates**: ConfigMap updates don't automatically restart pods
4. **Permissions**: ConfigMaps are namespace-scoped

## Advanced Examples

### Conditional ConfigMaps

```yaml
{{- if .Values.monitoring.enabled }}
multipleConfigMaps:
  - name: monitoring-config
    data:
      prometheus.yml: |
        # Monitoring config
{{- end }}
```

### Template Functions

```yaml
multipleConfigMaps:
  - name: app-config
    data:
      application.properties: |
        app.name={{ include "bss.fullname" . }}
        app.version={{ .Chart.AppVersion }}
        namespace={{ .Release.Namespace }}
```

### Environment-Specific Configuration

```yaml
multipleConfigMaps:
  - name: app-config
    data:
      application-{{ .Values.environment }}.properties: |
        {{- if eq .Values.environment "prod" }}
        logging.level.root=WARN
        {{- else }}
        logging.level.root=DEBUG
        {{- end }}
```

## Summary

The multiple ConfigMaps feature provides:

- ✅ Better organization of configuration files
- ✅ Granular control over labels and annotations
- ✅ Easier maintenance and updates
- ✅ Improved security through separation
- ✅ Better integration with GitOps workflows
- ✅ Backward compatibility with existing templates

Use this feature to organize your application configuration more effectively and maintain cleaner, more manageable Helm charts.