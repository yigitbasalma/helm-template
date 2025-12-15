# Service Template Usage Guide

The service template supports both single service configurations and multiple services through a flexible design.

## Detection Logic

The template uses `kindIs "slice"` to detect if the service configuration is a list:

- **List detected**: Loops through each service in the array
- **Single object**: Uses original service logic

## Configuration Formats

### 1. Single Service (Backward Compatible)

```yaml
service:
  type: ClusterIP
  port: 80
  targetPort: http
  annotations:
    prometheus.io/scrape: "true"
  labels:
    component: web
```

**Result**: Creates one service named `{{ include "bss.fullname" . }}`

### 2. Single Service with Multiple Ports

```yaml
service:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
      name: http
    - port: 443
      targetPort: 8443
      protocol: TCP
      name: https
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
```

**Result**: Creates one service with multiple ports

### 3. Multiple Services (List Format)

```yaml
service:
  - name: web
    type: ClusterIP
    port: 80
    targetPort: 8080
    annotations:
      prometheus.io/scrape: "true"
    labels:
      component: web
  
  - name: api
    type: ClusterIP
    ports:
      - port: 8080
        targetPort: 8080
        protocol: TCP
        name: http
      - port: 9090
        targetPort: 9090
        protocol: TCP
        name: metrics
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "9090"
    labels:
      component: api
```

**Result**: Creates multiple services:
- `{{ include "bss.fullname" . }}-web`
- `{{ include "bss.fullname" . }}-api`

## Service Naming Convention

### Single Service
- **Name**: `{{ include "bss.fullname" . }}`

### Multiple Services
- **With name**: `{{ include "bss.fullname" . }}-{{ $service.name }}`
- **Without name**: `{{ include "bss.fullname" . }}-{{ $index }}`

## Supported Fields

### Per Service Configuration

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | string | No | - | Service name suffix (for multiple services) |
| `type` | string | No | ClusterIP | Service type (ClusterIP, NodePort, LoadBalancer) |
| `port` | integer | No | 80 | Service port (if not using ports array) |
| `targetPort` | string/int | No | http | Target port on pods |
| `ports` | array | No | - | Array of port configurations |
| `annotations` | object | No | {} | Service annotations |
| `labels` | object | No | {} | Additional service labels |
| `selector` | object | No | - | Custom pod selector (overrides default) |

### Port Configuration (when using ports array)

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `port` | integer | Yes | - | Service port |
| `targetPort` | string/int | No | port value | Target port on pods |
| `protocol` | string | No | TCP | Protocol (TCP, UDP) |
| `name` | string | No | http | Port name |
| `nodePort` | integer | No | - | NodePort (for NodePort/LoadBalancer services) |

## Use Cases

### 1. Simple Web Application

```yaml
service:
  type: ClusterIP
  port: 80
  targetPort: 8080
```

### 2. Application with Metrics Endpoint

```yaml
service:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 8080
      name: http
    - port: 9090
      targetPort: 9090
      name: metrics
```

### 3. Microservices Architecture

```yaml
service:
  - name: frontend
    type: LoadBalancer
    port: 80
    targetPort: 3000
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
  
  - name: backend
    type: ClusterIP
    port: 8080
    targetPort: 8080
  
  - name: admin
    type: NodePort
    port: 8081
    targetPort: 8081
```

### 4. Database with Custom Selector

```yaml
service:
  - name: database
    type: ClusterIP
    port: 5432
    targetPort: 5432
    selector:
      app: postgresql
      tier: database
```

### 5. Headless Service for Service Discovery

```yaml
service:
  - name: headless
    type: ClusterIP
    clusterIP: None
    port: 80
    targetPort: 8080
```

## Template Logic Flow

```yaml
{{- if kindIs "slice" .Values.service }}
  # Multiple services - loop through array
  {{- range $index, $service := .Values.service }}
    # Create service with name suffix
    # Handle ports array or single port
    # Apply service-specific annotations/labels
  {{- end }}
{{- else }}
  # Single service - original logic
  # Handle ports array or single port
  # Apply global service configuration
{{- end }}
```

## Migration Guide

### From Single to Multiple Services

**Before:**
```yaml
service:
  type: ClusterIP
  port: 80
```

**After:**
```yaml
service:
  - name: web
    type: ClusterIP
    port: 80
```

### Adding Additional Services

```yaml
service:
  - name: web
    type: ClusterIP
    port: 80
  - name: api      # New service
    type: ClusterIP
    port: 8080
```

## Best Practices

1. **Consistent Naming**: Use descriptive names for multiple services
2. **Port Names**: Always name ports for better service mesh integration
3. **Annotations**: Use service-specific annotations for monitoring/routing
4. **Selectors**: Override selectors only when necessary
5. **Documentation**: Comment complex service configurations

## Troubleshooting

### Service Not Created
- Check if `service` is properly defined in values
- Verify YAML syntax for list vs object

### Wrong Service Name
- Ensure `name` field is set for multiple services
- Check `bss.fullname` template output

### Port Issues
- Verify `targetPort` matches container port
- Check `protocol` matches application requirements

### Selector Problems
- Ensure custom selectors match pod labels
- Default selector uses `bss.selectorLabels`

## Examples in Action

### Helm Install Commands

```bash
# Single service
helm install myapp . --set service.port=8080

# Multiple services
helm install myapp . -f multi-service-values.yaml

# Override service type
helm install myapp . --set service[0].type=LoadBalancer
```

### Generated Service Names

With `fullname: myapp`:

- Single: `myapp`
- Multiple with names: `myapp-web`, `myapp-api`
- Multiple without names: `myapp-0`, `myapp-1`