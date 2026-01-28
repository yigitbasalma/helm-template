# Base Helm Template Examples

This directory contains example configurations for the base Helm template.

## Pod Anti-Affinity Example

The `pod-anti-affinity-values.yaml` file demonstrates how to configure pod anti-affinity to spread replicas across different hosts.

### Usage

```bash
# Deploy with pod anti-affinity
helm install my-app ../base-helm-template -f examples/pod-anti-affinity-values.yaml
```

### Anti-Affinity Types

#### Required Anti-Affinity (Hard Requirement)
- **Use case**: Critical applications that must run on different nodes
- **Behavior**: Kubernetes will not schedule pods if the anti-affinity rule cannot be satisfied
- **Risk**: Pods may remain pending if not enough nodes are available

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
                - "{{ include \"base-template.name\" . }}"
        topologyKey: kubernetes.io/hostname
```

#### Preferred Anti-Affinity (Soft Requirement)
- **Use case**: Applications that benefit from spreading but can tolerate co-location
- **Behavior**: Kubernetes will try to satisfy the rule but will schedule pods even if it cannot
- **Benefit**: More flexible scheduling, pods won't get stuck pending

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - "{{ include \"base-template.name\" . }}"
          topologyKey: kubernetes.io/hostname
```

### Topology Keys

- `kubernetes.io/hostname`: Spread across different nodes
- `topology.kubernetes.io/zone`: Spread across different availability zones
- `topology.kubernetes.io/region`: Spread across different regions

### Best Practices

1. **Start with preferred anti-affinity** for most applications
2. **Use required anti-affinity** only for critical applications
3. **Consider your cluster size** - ensure you have enough nodes/zones
4. **Combine zone and host spreading** for maximum availability
5. **Test your configuration** in a development environment first

### Example Scenarios

#### High Availability Web Application
```yaml
replicaCount: 3
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: "{{ include \"base-template.name\" . }}"
        topologyKey: topology.kubernetes.io/zone
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: "{{ include \"base-template.name\" . }}"
          topologyKey: kubernetes.io/hostname
```

#### Development Environment (Flexible)
```yaml
replicaCount: 2
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 50
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: "{{ include \"base-template.name\" . }}"
          topologyKey: kubernetes.io/hostname
```