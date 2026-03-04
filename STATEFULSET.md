# StatefulSet Support

This Helm chart supports both Deployment and StatefulSet workload types. StatefulSets are ideal for stateful applications that require stable network identities, persistent storage, and ordered deployment/scaling.

## When to Use StatefulSet

Use StatefulSet when your application requires:

- **Stable, unique network identifiers**: Each pod gets a persistent hostname (e.g., `myapp-0`, `myapp-1`, `myapp-2`)
- **Stable, persistent storage**: Each pod gets its own persistent volume that persists across pod rescheduling
- **Ordered, graceful deployment and scaling**: Pods are created/deleted in order (0, 1, 2, ...)
- **Ordered, automated rolling updates**: Updates happen in reverse order with controlled rollout

### Common Use Cases

- Databases (PostgreSQL, MySQL, MongoDB, Cassandra)
- Distributed systems (Kafka, ZooKeeper, etcd)
- Caching systems (Redis Cluster, Memcached)
- Search engines (Elasticsearch)
- Message queues (RabbitMQ)

## Configuration

### Basic StatefulSet

Set `workloadType` to `statefulset` in your values.yaml:

```yaml
workloadType: statefulset
replicaCount: 3
```

### Volume Claim Templates

StatefulSets use `volumeClaimTemplates` to automatically create persistent volumes for each pod:

```yaml
statefulset:
  volumeClaimTemplates:
    - name: data
      accessModes:
        - ReadWriteOnce
      storage: 10Gi
      storageClassName: fast-ssd
```

Each pod will get its own PVC named `data-<pod-name>` (e.g., `data-myapp-0`, `data-myapp-1`).

### Multiple Volumes per Pod

You can define multiple volume claim templates:

```yaml
statefulset:
  volumeClaimTemplates:
    - name: data
      accessModes:
        - ReadWriteOnce
      storage: 50Gi
      storageClassName: fast-ssd
    
    - name: logs
      accessModes:
        - ReadWriteOnce
      storage: 10Gi
      storageClassName: standard
    
    - name: backup
      accessModes:
        - ReadWriteOnce
      storage: 100Gi
      storageClassName: standard
```

### Volume Mounts

Mount the volumes in your container:

```yaml
volumeMounts:
  - name: data
    mountPath: /var/lib/app/data
  - name: logs
    mountPath: /var/log/app
  - name: backup
    mountPath: /backup
```

## Command and Args Support

Both Deployment and StatefulSet support `command` and `args` fields:

```yaml
command:
  - /bin/sh
  - -c

args:
  - |
    echo "Starting application..."
    exec /app/start.sh
```

Or for Redis example:

```yaml
command:
  - redis-server

args:
  - --cluster-enabled
  - "yes"
  - --appendonly
  - "yes"
  - --dir
  - /data
```

## Service Configuration

StatefulSets work with both regular and headless services. The chart automatically creates the service based on your configuration:

```yaml
service:
  type: ClusterIP
  port: 6379
```

For direct pod access, you can access pods via:
- `<pod-name>.<service-name>.<namespace>.svc.cluster.local`
- Example: `myapp-0.myapp.default.svc.cluster.local`

## Pod Anti-Affinity

It's recommended to use pod anti-affinity with StatefulSets to spread replicas across nodes:

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

## Examples

### Example 1: Basic StatefulSet

See [statefulset-basic-values.yaml](examples/statefulset-basic-values.yaml) for a simple nginx StatefulSet with single volume.

```bash
helm install my-app . -f examples/statefulset-basic-values.yaml
```

### Example 2: Database with Multiple Volumes

See [statefulset-multiple-pvcs-values.yaml](examples/statefulset-multiple-pvcs-values.yaml) for a PostgreSQL StatefulSet with multiple volumes (data, WAL, backup).

```bash
helm install postgres . -f examples/statefulset-multiple-pvcs-values.yaml
```

### Example 3: Redis Cluster

See [statefulset-redis-cluster-values.yaml](examples/statefulset-redis-cluster-values.yaml) for a production-ready Redis cluster configuration.

```bash
helm install redis-cluster . -f examples/statefulset-redis-cluster-values.yaml
```

## Deployment vs StatefulSet

| Feature | Deployment | StatefulSet |
|---------|-----------|-------------|
| Pod naming | Random suffix | Ordered index (0, 1, 2...) |
| Network identity | Unstable | Stable hostname |
| Storage | Shared or no persistence | Per-pod persistent volumes |
| Scaling order | Parallel | Sequential (ordered) |
| Update strategy | Rolling (parallel) | Rolling (ordered) |
| Use case | Stateless apps | Stateful apps |

## Switching Between Workload Types

To switch from Deployment to StatefulSet:

1. Set `workloadType: statefulset`
2. Add `volumeClaimTemplates` under `statefulset`
3. Configure `volumeMounts` for your containers
4. Consider adding pod anti-affinity

To switch from StatefulSet to Deployment:

1. Set `workloadType: deployment`
2. Use `multiplePVCs` for shared storage if needed
3. Remove `statefulset.volumeClaimTemplates`

**Note**: Switching workload types requires deleting the existing workload first, as Kubernetes doesn't support in-place conversion.

## Volume Management

### StatefulSet Volumes (volumeClaimTemplates)

- Created automatically for each pod
- Named with pattern: `<volume-name>-<pod-name>`
- Persist when pod is deleted/rescheduled
- Must be manually deleted when StatefulSet is deleted

### Shared Volumes (multiplePVCs)

For volumes shared across all pods (works with both Deployment and StatefulSet):

```yaml
multiplePVCs:
  - name: shared-config
    accessModes:
      - ReadWriteMany
    storage: 5Gi
    storageClassName: nfs

volumes:
  - name: shared-config
    persistentVolumeClaim:
      claimName: shared-config

volumeMounts:
  - name: shared-config
    mountPath: /etc/config
```

## Best Practices

1. **Use pod anti-affinity** to spread replicas across nodes for high availability
2. **Set appropriate resource requests/limits** for stable performance
3. **Configure probes** (liveness, readiness) for health monitoring
4. **Use fast storage classes** (SSD) for performance-critical applications
5. **Plan storage capacity** carefully - PVCs are not automatically resized
6. **Test scaling operations** in non-production environments first
7. **Implement proper backup strategies** for persistent data
8. **Use headless services** when you need direct pod-to-pod communication

## Troubleshooting

### Pods stuck in Pending

Check PVC status:
```bash
kubectl get pvc
kubectl describe pvc <pvc-name>
```

Common issues:
- No available storage class
- Insufficient storage capacity
- Storage class doesn't support dynamic provisioning

### Pods not starting in order

StatefulSets wait for each pod to be Ready before starting the next. Check:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Scaling issues

StatefulSets scale sequentially. If scaling is stuck:
```bash
kubectl get statefulset
kubectl describe statefulset <name>
```

### Deleting StatefulSet

To delete StatefulSet and its PVCs:
```bash
# Delete StatefulSet
helm uninstall <release-name>

# Delete PVCs (they are not automatically deleted)
kubectl delete pvc -l app.kubernetes.io/instance=<release-name>
```

## Migration Guide

See [MIGRATION-TO-STATEFULSET.md](MIGRATION-TO-STATEFULSET.md) for detailed migration instructions from Deployment to StatefulSet.
