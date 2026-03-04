# Base Helm Template Examples

This directory contains example configurations for the base Helm template.

## Multiple PVCs Example

The `multiple-pvcs-values.yaml` file demonstrates how to configure multiple Persistent Volume Claims for different storage needs.

### Usage

```bash
# Deploy with multiple PVCs
helm install my-app ../base-helm-template -f examples/multiple-pvcs-values.yaml
```

### Features

- **Multiple storage types**: Configure different storage classes for different needs
- **Access modes**: Support for ReadWriteOnce, ReadWriteMany, ReadOnlyMany
- **Labels and annotations**: Add metadata for organization and automation
- **Volume binding**: Bind to specific PVs or use selectors
- **Volume modes**: Support for Filesystem and Block storage

### Common Use Cases

#### Application with Multiple Storage Needs
```yaml
multiplePVCs:
  - name: app-data
    accessModes:
      - ReadWriteOnce
    storage: 10Gi
    storageClassName: fast-ssd
  
  - name: logs-storage
    accessModes:
      - ReadWriteMany
    storage: 5Gi
    storageClassName: standard
```

#### Database with Separate WAL Storage
```yaml
multiplePVCs:
  - name: postgres-data
    accessModes:
      - ReadWriteOnce
    storage: 100Gi
    storageClassName: premium-ssd
  
  - name: postgres-wal
    accessModes:
      - ReadWriteOnce
    storage: 50Gi
    storageClassName: ultra-ssd
```

### Storage Classes

Choose appropriate storage classes based on your needs:

- **fast-ssd / premium-ssd**: High IOPS, low latency (databases, caches)
- **standard**: Balanced performance and cost (logs, backups)
- **nfs-storage**: Shared access across multiple pods (media, shared files)
- **block-storage**: Raw block devices for specialized workloads

### Best Practices

1. **Use appropriate storage classes** for each workload type
2. **Add labels and annotations** for organization and automation
3. **Consider access modes** based on your application architecture
4. **Plan for backups** using annotations to mark critical data
5. **Monitor storage usage** and adjust sizes as needed

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