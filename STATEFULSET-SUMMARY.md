# StatefulSet Implementation Summary

This document summarizes the StatefulSet support added to the base-helm-template.

## What Was Added

### 1. StatefulSet Template
- **File**: `templates/statefulset.yaml`
- **Features**:
  - Conditional rendering based on `workloadType` value
  - Support for volumeClaimTemplates (per-pod persistent volumes)
  - Identical pod spec to Deployment for consistency
  - Support for all existing features (probes, resources, affinity, etc.)

### 2. Args Support
- **Files**: `templates/deployment.yaml`, `templates/statefulset.yaml`, `values.yaml`
- **Features**:
  - Added `args` field support (similar to `command`)
  - Works with both Deployment and StatefulSet
  - Useful for passing arguments to container entrypoint

### 3. Configuration Options
- **File**: `values.yaml`
- **New Fields**:
  ```yaml
  workloadType: deployment  # or statefulset
  args: []  # Container arguments
  statefulset:
    volumeClaimTemplates: []  # Per-pod volumes
  ```

### 4. Documentation
- **STATEFULSET.md**: Comprehensive guide on StatefulSet usage
- **MIGRATION-TO-STATEFULSET.md**: Step-by-step migration guide
- **STATEFULSET-SUMMARY.md**: This summary document

### 5. Examples
- **statefulset-basic-values.yaml**: Simple nginx StatefulSet
- **statefulset-multiple-pvcs-values.yaml**: PostgreSQL with multiple volumes
- **statefulset-redis-cluster-values.yaml**: Production Redis cluster
- **statefulset-quickstart.md**: Quick start guide

## Key Features

### Workload Type Selection
```yaml
# Use Deployment (default)
workloadType: deployment

# Use StatefulSet
workloadType: statefulset
```

### Volume Claim Templates
```yaml
statefulset:
  volumeClaimTemplates:
    - name: data
      accessModes:
        - ReadWriteOnce
      storage: 10Gi
      storageClassName: fast-ssd
      labels:
        app.kubernetes.io/component: storage
      annotations:
        description: "Pod data storage"
```

### Command and Args
```yaml
command:
  - /bin/sh
  - -c

args:
  - |
    echo "Starting..."
    exec /app/start.sh
```

## Usage Examples

### Basic StatefulSet
```bash
helm install my-app . --set workloadType=statefulset \
  --set statefulset.volumeClaimTemplates[0].name=data \
  --set statefulset.volumeClaimTemplates[0].storage=10Gi
```

### Using Example Files
```bash
# Basic nginx
helm install nginx . -f examples/statefulset-basic-values.yaml

# PostgreSQL with multiple volumes
helm install postgres . -f examples/statefulset-multiple-pvcs-values.yaml

# Redis cluster
helm install redis . -f examples/statefulset-redis-cluster-values.yaml
```

## Comparison: Deployment vs StatefulSet

| Feature | Deployment | StatefulSet |
|---------|-----------|-------------|
| **Workload Type** | `workloadType: deployment` | `workloadType: statefulset` |
| **Pod Naming** | Random suffix | Ordered (0, 1, 2...) |
| **Network Identity** | Unstable | Stable hostname |
| **Storage** | Shared PVC or no persistence | Per-pod PVC |
| **Scaling** | Parallel | Sequential |
| **Updates** | Parallel rolling | Sequential rolling |
| **Use Case** | Stateless apps | Stateful apps |

## File Structure

```
base-helm-template/
├── templates/
│   ├── deployment.yaml          # Updated with args support
│   ├── statefulset.yaml         # NEW: StatefulSet template
│   ├── pvc.yaml                 # Existing (for shared PVCs)
│   └── ...
├── examples/
│   ├── statefulset-basic-values.yaml              # NEW
│   ├── statefulset-multiple-pvcs-values.yaml      # NEW
│   ├── statefulset-redis-cluster-values.yaml      # NEW
│   └── statefulset-quickstart.md                  # NEW
├── values.yaml                  # Updated with workloadType, args, statefulset
├── STATEFULSET.md              # NEW: Comprehensive guide
├── MIGRATION-TO-STATEFULSET.md # NEW: Migration guide
└── STATEFULSET-SUMMARY.md      # NEW: This file
```

## Backward Compatibility

All changes are backward compatible:
- Default `workloadType` is `deployment`
- Existing Deployment configurations work without changes
- New fields are optional
- No breaking changes to existing functionality

## Testing

### Test Deployment (Existing Functionality)
```bash
# Should work as before
helm install test . --set image.repository=nginx
kubectl get deployment
```

### Test StatefulSet
```bash
# Test basic StatefulSet
helm install test . -f examples/statefulset-basic-values.yaml
kubectl get statefulset
kubectl get pvc

# Test scaling
kubectl scale statefulset test --replicas=5

# Test persistence
kubectl exec test-0 -- sh -c 'echo "data" > /usr/share/nginx/html/test.txt'
kubectl delete pod test-0
kubectl exec test-0 -- cat /usr/share/nginx/html/test.txt
```

### Test Args Support
```bash
# Test with command and args
cat > test-args.yaml <<EOF
workloadType: deployment
image:
  repository: busybox
  tag: latest
command: ["/bin/sh", "-c"]
args: ["echo 'Hello World'; sleep 3600"]
EOF

helm install test . -f test-args.yaml
kubectl logs <pod-name>  # Should show "Hello World"
```

## Common Use Cases

### 1. Database (PostgreSQL)
```yaml
workloadType: statefulset
replicaCount: 3
image:
  repository: postgres
  tag: "14"
statefulset:
  volumeClaimTemplates:
    - name: data
      storage: 50Gi
      storageClassName: fast-ssd
```

### 2. Cache (Redis)
```yaml
workloadType: statefulset
replicaCount: 6
image:
  repository: redis
  tag: "7.0"
command: [redis-server]
args:
  - --cluster-enabled
  - "yes"
  - --appendonly
  - "yes"
```

### 3. Message Queue (RabbitMQ)
```yaml
workloadType: statefulset
replicaCount: 3
image:
  repository: rabbitmq
  tag: "3.11-management"
statefulset:
  volumeClaimTemplates:
    - name: data
      storage: 20Gi
```

## Best Practices

1. **Use pod anti-affinity** to spread replicas across nodes
2. **Set resource limits** to prevent resource exhaustion
3. **Configure probes** for health monitoring
4. **Use fast storage** (SSD) for performance-critical apps
5. **Plan storage capacity** - PVCs don't auto-resize
6. **Implement backups** for persistent data
7. **Test in dev** before production deployment
8. **Monitor PVC usage** to prevent storage exhaustion

## Troubleshooting

### Issue: PVC Stuck in Pending
```bash
kubectl describe pvc <pvc-name>
kubectl get storageclass
```

### Issue: Pods Not Starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Issue: Data Not Persisting
```bash
kubectl get pvc
kubectl exec <pod-name> -- df -h
```

## Next Steps

1. Review [STATEFULSET.md](STATEFULSET.md) for detailed documentation
2. Try examples in [examples/](examples/) directory
3. Read [MIGRATION-TO-STATEFULSET.md](MIGRATION-TO-STATEFULSET.md) for migration
4. Check [statefulset-quickstart.md](examples/statefulset-quickstart.md) for quick start

## Support

For issues or questions:
1. Check documentation in this repository
2. Review examples for similar use cases
3. Test in development environment first
4. Consult Kubernetes StatefulSet documentation

## Version History

- **v1.0**: Initial StatefulSet support
  - Added StatefulSet template
  - Added args support
  - Added volumeClaimTemplates
  - Added comprehensive documentation
  - Added examples for common use cases
