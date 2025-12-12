# Image Tag Usage Examples

This document shows how the image tag resolution works in the Helm template.

## Priority Order

The image tag is resolved in the following priority order:

1. `global.image.tag` (if set)
2. `image.tag` (if set)
3. `Chart.AppVersion` (fallback)

## Example Configurations

### Example 1: Using local image tag

```yaml
# values.yaml
image:
  repository: myapp
  tag: "v1.2.3"
```

**Result:** `myapp:v1.2.3`

### Example 2: Using global image tag (overrides local)

```yaml
# values.yaml
global:
  image:
    tag: "v2.0.0"

image:
  repository: myapp
  tag: "v1.2.3"  # This will be ignored
```

**Result:** `myapp:v2.0.0`

### Example 3: No tags specified (uses Chart.AppVersion)

```yaml
# values.yaml
image:
  repository: myapp
  tag: ""

# Chart.yaml
appVersion: "1.0.0"
```

**Result:** `myapp:1.0.0`

### Example 4: Global override in parent chart

When using this chart as a dependency:

```yaml
# parent-chart/values.yaml
global:
  image:
    tag: "production-v3.1.0"

my-service:
  image:
    repository: myapp
    tag: "dev-v1.0.0"  # This will be ignored
```

**Result:** `myapp:production-v3.1.0`

## Use Cases

### Development Environment

```yaml
# dev-values.yaml
image:
  repository: myapp
  tag: "dev-latest"
```

### Staging Environment with Global Override

```yaml
# staging-values.yaml
global:
  image:
    tag: "staging-v2.1.0"

image:
  repository: myapp
  tag: "dev-latest"  # Ignored due to global override
```

### Production with Umbrella Chart

```yaml
# umbrella-chart/values.yaml
global:
  image:
    tag: "v3.0.0"  # All services use this tag

api-service:
  image:
    repository: mycompany/api

web-service:
  image:
    repository: mycompany/web

worker-service:
  image:
    repository: mycompany/worker
```

All services will use tag `v3.0.0`.

## Helm Commands

### Install with local tag

```bash
helm install myapp . --set image.tag=v1.2.3
```

### Install with global tag override

```bash
helm install myapp . --set global.image.tag=v2.0.0
```

### Install with both (global takes precedence)

```bash
helm install myapp . \
  --set image.tag=v1.2.3 \
  --set global.image.tag=v2.0.0
```

Result: Uses `v2.0.0`

## Template Logic

The template uses Helm's `coalesce` function:

```yaml
image: "{{ .Values.image.repository }}:{{ coalesce ((.Values.global).image).tag .Values.image.tag .Chart.AppVersion }}"
```

This safely handles:
- Missing `global` section
- Missing `global.image` section  
- Missing `global.image.tag` field
- Empty string values
- Fallback to Chart.AppVersion