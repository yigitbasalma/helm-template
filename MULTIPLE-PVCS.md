# Multiple PVCs Support

The base Helm template supports creating multiple Persistent Volume Claims (PVCs) with different configurations for various storage needs.

## Overview

The `multiplePVCs` feature allows you to:

- Create multiple PVCs with different storage classes
- Configure different access modes per PVC
- Add custom labels and annotations for organization
- Bind to specific PVs or use selectors
- Support both Filesystem and Block volume modes

## Configuration

### Basic Example

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

### Full Configuration Options

```yaml
multiplePVCs:
  - name: my-pvc                    # Required: PVC name
    labels:                         # Optional: Additional labels
      app.kubernetes.io/component: storage
      tier: database
    annotations:                    # Optional: Annotations
      backup: "true"
      description: "Database storage"
    accessModes:                    # Required: Access modes
      - ReadWriteOnce
    storage: 100Gi                  # Required: Storage size
    storageClassName: premium-ssd   # Optional: Storage class
    volumeName: pv-001              # Optional: Bind to specific PV
    volumeMode: Filesystem          # Optional: Filesystem or Block
    selector:                       # Optional: PV selector
      matchLabels:
        environment: production
```

## Access Modes

- **ReadWriteOnce (RWO)**: Volume can be mounted as read-write by a single node
- **ReadWriteMany (RWX)**: Volume can be mounted as read-write by many nodes
- **ReadOnlyMany (ROX)**: Volume can be mounted as read-only by many nodes

## Storage Classes

Choose appropriate storage classes based on your workload:

### Performance Tiers

- **Ultra/Premium SSD**: Highest IOPS, lowest latency
  - Use for: Databases, high-performance applications
  - Example: `premium-ssd`, `ultra-ssd`

- **Fast SSD**: Balanced performance
  - Use for: Application data, caches
  - Example: `fast-ssd`, `ssd`

- **Standard**: Cost-effective
  - Use for: Logs, backups, non-critical data
  - Example: `standard`, `hdd`

### Shared Storage

- **NFS/CephFS**: Network file systems
  - Use for: Shared media, configuration files
  - Supports: ReadWriteMany
  - Example: `nfs-storage`, `cephfs`

## Common Use Cases

### 1. Application with Multiple Storage Types

```yaml
multiplePVCs:
  # Fast storage for application data
  - name: app-data
    labels:
      app.kubernetes.io/component: storage
    accessModes:
      - ReadWriteOnce
    storage: 10Gi
    storageClassName: fast-ssd
  
  # Standard storage for logs
  - name: logs
    labels:
      app.kubernetes.io/component: logs
    accessModes:
      - ReadWriteMany
    storage: 5Gi
    storageClassName: standard
  
  # Shared storage for media
  - name: media
    labels:
      app.kubernetes.io/component: media
    accessModes:
      - ReadWriteMany
    storage: 50Gi
    storageClassName: nfs-storage

volumes:
  - name: app-data
    persistentVolumeClaim:
      claimName: app-data
  - name: logs
    persistentVolumeClaim:
      claimName: logs
  - name: media
    persistentVolumeClaim:
      claimName: media

volumeMounts:
  - name: app-data
    mountPath: /app/data
  - name: logs
    mountPath: /app/logs
  - name: media
    mountPath: /app/media
```

### 2. Database with Separate WAL Storage

```yaml
multiplePVCs:
  # Main database storage
  - name: postgres-data
    labels:
      app.kubernetes.io/component: database
    annotations:
      backup: "true"
      backup.schedule: "0 2 * * *"
    accessModes:
      - ReadWriteOnce
    storage: 100Gi
    storageClassName: premium-ssd
  
  # Write-Ahead Log storage (higher IOPS)
  - name: postgres-wal
    labels:
      app.kubernetes.io/component: database-wal
    accessModes:
      - ReadWriteOnce
    storage: 50Gi
    storageClassName: ultra-ssd

volumes:
  - name: postgres-data
    persistentVolumeClaim:
      claimName: postgres-data
  - name: postgres-wal
    persistentVolumeClaim:
      claimName: postgres-wal

volumeMounts:
  - name: postgres-data
    mountPath: /var/lib/postgresql/data
  - name: postgres-wal
    mountPath: /var/lib/postgresql/wal
```

### 3. Stateful Application with Specific PV Binding

```yaml
multiplePVCs:
  - name: app-storage
    labels:
      app.kubernetes.io/component: storage
    accessModes:
      - ReadWriteOnce
    storage: 100Gi
    storageClassName: premium-ssd
    # Bind to specific PV
    volumeName: pv-app-001
    # Or use selector
    selector:
      matchLabels:
        environment: production
        tier: application
```

### 4. Block Storage for Raw Device Access

```yaml
multiplePVCs:
  - name: raw-block-storage
    labels:
      app.kubernetes.io/component: block-storage
    accessModes:
      - ReadWriteOnce
    storage: 100Gi
    storageClassName: block-storage
    volumeMode: Block  # Raw block device

volumes:
  - name: raw-block
    persistentVolumeClaim:
      claimName: raw-block-storage

volumeMounts:
  - name: raw-block
    devicePath: /dev/xvda  # Block device path
```

## Labels and Annotations

### Recommended Labels

```yaml
labels:
  app.kubernetes.io/component: storage    # Component type
  tier: database                          # Application tier
  environment: production                 # Environment
```

### Useful Annotations

```yaml
annotations:
  description: "Database storage"         # Human-readable description
  backup: "true"                          # Mark for backup
  backup.schedule: "0 2 * * *"           # Backup schedule
  backup.retention: "7d"                  # Backup retention
  monitoring: "true"                      # Enable monitoring
```

## Best Practices

### 1. Storage Class Selection

- Use premium/ultra storage for databases and high-IOPS workloads
- Use standard storage for logs and non-critical data
- Use shared storage (NFS/CephFS) only when multiple pods need access

### 2. Access Modes

- Use ReadWriteOnce (RWO) for single-pod workloads
- Use ReadWriteMany (RWX) only when necessary (logs, shared media)
- Consider application architecture before choosing RWX

### 3. Sizing

- Start with reasonable sizes and monitor usage
- Plan for growth but avoid over-provisioning
- Use separate PVCs for different data types

### 4. Organization

- Use descriptive names for PVCs
- Add labels for filtering and organization
- Use annotations for automation and documentation

### 5. Backup Strategy

- Mark critical PVCs with backup annotations
- Use separate PVCs for data that needs different backup policies
- Document backup schedules in annotations

### 6. Monitoring

- Monitor PVC usage and capacity
- Set up alerts for high usage
- Track IOPS and latency for performance-critical storage

## Migration from Legacy PVC

If you're using the legacy single PVC configuration:

```yaml
# Old (deprecated)
pvc:
  enabled: true
  name: data
  accessMode: ReadWriteOnce
  storage: 5Gi
  storageClass: standard
```

Migrate to:

```yaml
# New
multiplePVCs:
  - name: data
    accessModes:
      - ReadWriteOnce
    storage: 5Gi
    storageClassName: standard
```

## Troubleshooting

### PVC Stuck in Pending

Check:
1. Storage class exists: `kubectl get storageclass`
2. Sufficient storage available
3. Access mode supported by storage class
4. PV selector matches available PVs

### PVC Not Mounting

Check:
1. PVC is bound: `kubectl get pvc`
2. Volume name matches in deployment
3. Mount path doesn't conflict with other volumes
4. Node has necessary drivers/plugins

### Performance Issues

Check:
1. Storage class IOPS limits
2. Network latency (for network storage)
3. Volume size (some classes scale IOPS with size)
4. Multiple pods accessing same RWX volume

## Examples

See `examples/multiple-pvcs-values.yaml` for comprehensive examples.

## References

- [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Volume Modes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#volume-mode)
