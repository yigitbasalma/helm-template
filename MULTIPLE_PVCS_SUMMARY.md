# Multiple PVCs Implementation Summary

This document summarizes the multiple PVCs support in the base-helm-template.

## Overview

The template supports two types of persistent volume configurations:

1. **Multiple PVCs** (`multiplePVCs`) - Shared PVCs created independently, used with both Deployment and StatefulSet
2. **Volume Claim Templates** (`statefulset.volumeClaimTemplates`) - Per-pod PVCs automatically created for StatefulSet replicas

## Multiple PVCs (Shared Storage)

### Purpose
Create multiple independent PVCs that can be shared across pods or used for different purposes.

### Configuration

```yaml
multiplePVCs:
  - name: app-data
    labels:
      app.kubernetes.io/component: storage
    annotations:
      backup: "true"
    accessModes:
      - ReadWriteOnce
    storage: 10Gi
    storageClassName: fast-ssd
  
  - name: shared-config
    labels:
      app.kubernetes.io/component: config
    accessModes:
      - ReadWriteMany  # Shared across pods
    storage: 1Gi
    storageClassName: nfs
```

### Usage with Volumes

```yaml
volumes:
  - name: app-data
    persistentVolumeClaim:
      claimName: app-data
  - name: shared-config
    persistentVolumeClaim:
      claimName: shared-config

volumeMounts:
  - name: app-data
    mountPath: /app/data
  - name: shared-config
    mountPath: /etc/config
```

### Characteristics
- Created as separate PVC resources
- Can be shared across multiple pods (with ReadWriteMany)
- Exist independently of pods
- Must be manually deleted when no longer needed
- Works with both Deployment and StatefulSet

## Volume Claim Templates (StatefulSet)

### Purpose
Automatically create a dedicated PVC for each pod replica in a StatefulSet.

### Configuration

```yaml
workloadType: statefulset

statefulset:
  volumeClaimTemplates:
    - name: data
      labels:
        app.kubernetes.io/component: storage
      annotations:
        description: "Pod data storage"
      accessModes:
        - ReadWriteOnce
      storage: 10Gi
      storageClassName: fast-ssd
    
    - name: logs
      labels:
        app.kubernetes.io/component: logs
      accessModes:
        - ReadWriteOnce
      storage: 5Gi
      storageClassName: standard
```

### Usage with Volume Mounts

```yaml
volumeMounts:
  - name: data
    mountPath: /var/lib/app/data
  - name: logs
    mountPath: /var/log/app
```

### Characteristics
- Automatically created for each pod replica
- Named with pattern: `<volume-name>-<pod-name>` (e.g., `data-myapp-0`, `data-myapp-1`)
- Each pod gets its own dedicated storage
- Persist when pod is deleted/rescheduled
- Only works with StatefulSet
- Must be manually deleted after StatefulSet deletion

## Comparison

| Feature | Multiple PVCs | Volume Claim Templates |
|---------|--------------|------------------------|
| **Workload Type** | Deployment, StatefulSet | StatefulSet only |
| **Creation** | Manual (via template) | Automatic (per pod) |
| **Naming** | Custom name | `<name>-<pod-name>` |
| **Sharing** | Can be shared (ReadWriteMany) | Per-pod (not shared) |
| **Use Case** | Shared storage, config | Per-pod persistent data |
| **Lifecycle** | Independent | Tied to StatefulSet |

## Use Cases

### Multiple PVCs

1. **Shared Configuration**
   ```yaml
   multiplePVCs:
     - name: shared-config
       accessModes:
         - ReadWriteMany
       storage: 1Gi
       storageClassName: nfs
   ```

2. **Backup Storage**
   ```yaml
   multiplePVCs:
     - name: backup-storage
       accessModes:
         - ReadWriteOnce
       storage: 100Gi
       storageClassName: standard
   ```

3. **Log Aggregation**
   ```yaml
   multiplePVCs:
     - name: logs
       accessModes:
         - ReadWriteMany
       storage: 20Gi
       storageClassName: nfs
   ```

### Volume Claim Templates

1. **Database Storage**
   ```yaml
   statefulset:
     volumeClaimTemplates:
       - name: data
         storage: 50Gi
         storageClassName: fast-ssd
   ```

2. **Multiple Volumes per Database Pod**
   ```yaml
   statefulset:
     volumeClaimTemplates:
       - name: data
         storage: 50Gi
       - name: wal
         storage: 20Gi
       - name: backup
         storage: 100Gi
   ```

3. **Cache Storage**
   ```yaml
   statefulset:
     volumeClaimTemplates:
       - name: cache
         storage: 20Gi
         storageClassName: fast-ssd
   ```

## Combined Usage

You can use both types together:

```yaml
workloadType: statefulset
replicaCount: 3

# Per-pod storage (different for each pod)
statefulset:
  volumeClaimTemplates:
    - name: data
      storage: 10Gi
      storageClassName: fast-ssd

# Shared storage (same for all pods)
multiplePVCs:
  - name: shared-config
    accessModes:
      - ReadWriteMany
    storage: 1Gi
    storageClassName: nfs

volumes:
  - name: shared-config
    persistentVolumeClaim:
      claimName: shared-config

volumeMounts:
  - name: data          # Per-pod volume
    mountPath: /app/data
  - name: shared-config # Shared volume
    mountPath: /etc/config
```

Result:
- Each pod gets its own `data` PVC: `data-myapp-0`, `data-myapp-1`, `data-myapp-2`
- All pods share the same `shared-config` PVC

## Storage Classes

### Common Storage Classes

```yaml
# Fast SSD for databases
storageClassName: fast-ssd

# Standard HDD for logs
storageClassName: standard

# Network storage for shared access
storageClassName: nfs

# Local storage for high performance
storageClassName: local-storage
```

### Access Modes

```yaml
# Single node read-write
accessModes:
  - ReadWriteOnce

# Multiple nodes read-write (requires NFS or similar)
accessModes:
  - ReadWriteMany

# Multiple nodes read-only
accessModes:
  - ReadOnlyMany
```

## Best Practices

1. **Use Volume Claim Templates for StatefulSet**
   - Each pod needs its own data (databases, caches)
   - Data should persist across pod restarts
   - Pods need stable storage identity

2. **Use Multiple PVCs for Shared Storage**
   - Configuration files shared across pods
   - Shared cache or temporary storage
   - Centralized logging or backup storage

3. **Choose Appropriate Storage Classes**
   - Fast SSD for databases and performance-critical apps
   - Standard HDD for logs and backups
   - NFS for shared storage across nodes

4. **Set Appropriate Sizes**
   - Plan for growth
   - Monitor usage regularly
   - Consider backup storage needs

5. **Use Labels and Annotations**
   - Identify purpose and ownership
   - Track backup requirements
   - Document storage policies

## Examples

See the following example files:
- [examples/multiple-pvcs-values.yaml](examples/multiple-pvcs-values.yaml) - Multiple PVCs examples
- [examples/statefulset-basic-values.yaml](examples/statefulset-basic-values.yaml) - Basic StatefulSet with volume claim template
- [examples/statefulset-multiple-pvcs-values.yaml](examples/statefulset-multiple-pvcs-values.yaml) - StatefulSet with multiple volume claim templates

## Troubleshooting

### PVC Stuck in Pending

```bash
# Check PVC status
kubectl get pvc
kubectl describe pvc <pvc-name>

# Check storage class
kubectl get storageclass
kubectl describe storageclass <class-name>
```

### Storage Not Available

```bash
# Check available storage
kubectl get pv

# Check node capacity
kubectl describe node <node-name>
```

### Access Mode Issues

```bash
# Verify access mode is supported
kubectl describe storageclass <class-name>

# Check PVC access mode
kubectl get pvc <pvc-name> -o yaml | grep accessModes
```

## Cleanup

### Delete Multiple PVCs

```bash
# Delete specific PVC
kubectl delete pvc <pvc-name>

# Delete all PVCs for a release
kubectl delete pvc -l app.kubernetes.io/instance=<release-name>
```

### Delete StatefulSet PVCs

```bash
# StatefulSet PVCs are not automatically deleted
# Delete manually after StatefulSet deletion
kubectl delete pvc -l app.kubernetes.io/instance=<release-name>

# Or delete specific pod PVCs
kubectl delete pvc data-myapp-0 data-myapp-1 data-myapp-2
```

## Documentation

- [MULTIPLE-PVCS.md](MULTIPLE-PVCS.md) - Detailed multiple PVCs guide
- [STATEFULSET.md](STATEFULSET.md) - StatefulSet documentation
- [MIGRATION-TO-STATEFULSET.md](MIGRATION-TO-STATEFULSET.md) - Migration guide
