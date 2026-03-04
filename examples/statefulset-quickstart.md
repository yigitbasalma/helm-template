# StatefulSet Quick Start Guide

This guide helps you quickly get started with StatefulSet in the base-helm-template.

## Quick Start

### 1. Basic StatefulSet (Nginx)

```bash
# Install with basic StatefulSet configuration
helm install my-nginx . -f examples/statefulset-basic-values.yaml

# Check status
kubectl get statefulset
kubectl get pods
kubectl get pvc

# Access a specific pod
kubectl exec my-nginx-0 -- hostname
```

### 2. Database with Multiple Volumes (PostgreSQL)

```bash
# Install PostgreSQL with multiple volumes
helm install postgres . -f examples/statefulset-multiple-pvcs-values.yaml

# Check status
kubectl get statefulset postgres
kubectl get pvc -l app.kubernetes.io/instance=postgres

# Connect to database
kubectl exec -it postgres-0 -- psql -U postgres
```

### 3. Redis Cluster

```bash
# Install Redis cluster
helm install redis . -f examples/statefulset-redis-cluster-values.yaml

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=redis --timeout=300s

# Check cluster status
kubectl exec redis-0 -- redis-cli cluster info
```

## Common Operations

### Scaling

```bash
# Scale up
kubectl scale statefulset <name> --replicas=5

# Scale down (removes highest-numbered pods first)
kubectl scale statefulset <name> --replicas=3
```

### Accessing Pods

```bash
# Access specific pod
kubectl exec -it <name>-0 -- /bin/bash

# Access via service (round-robin)
kubectl port-forward svc/<name> 8080:80

# Access specific pod via DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup <name>-0.<name>.default.svc.cluster.local
```

### Updating

```bash
# Update image
helm upgrade <name> . --set image.tag=2.0.0

# Pods will be updated in reverse order (highest to lowest)
kubectl rollout status statefulset <name>
```

### Deleting

```bash
# Delete StatefulSet (keeps PVCs)
helm uninstall <name>

# Delete PVCs manually
kubectl delete pvc -l app.kubernetes.io/instance=<name>
```

## Minimal Configuration

The absolute minimum to create a StatefulSet:

```yaml
# minimal-statefulset.yaml
workloadType: statefulset
replicaCount: 3

image:
  repository: nginx
  tag: "1.21"

service:
  port: 80

statefulset:
  volumeClaimTemplates:
    - name: data
      accessModes:
        - ReadWriteOnce
      storage: 1Gi
      storageClassName: standard

volumeMounts:
  - name: data
    mountPath: /usr/share/nginx/html
```

Install:
```bash
helm install test . -f minimal-statefulset.yaml
```

## Testing StatefulSet Features

### Test Stable Network Identity

```bash
# Get pod hostnames
for i in 0 1 2; do
  kubectl exec <name>-$i -- hostname
done

# Delete a pod and verify it gets the same name
kubectl delete pod <name>-1
kubectl get pods -w  # Watch it recreate with same name
```

### Test Persistent Storage

```bash
# Write data to pod-0
kubectl exec <name>-0 -- sh -c 'echo "test data" > /data/test.txt'

# Verify data
kubectl exec <name>-0 -- cat /data/test.txt

# Delete pod and verify data persists
kubectl delete pod <name>-0
kubectl wait --for=condition=ready pod <name>-0 --timeout=60s
kubectl exec <name>-0 -- cat /data/test.txt  # Should still show "test data"
```

### Test Ordered Scaling

```bash
# Scale up and watch order
kubectl scale statefulset <name> --replicas=5
kubectl get pods -w  # Watch pods created in order: 3, 4

# Scale down and watch order
kubectl scale statefulset <name> --replicas=3
kubectl get pods -w  # Watch pods deleted in reverse: 4, 3
```

## Troubleshooting

### Pod Stuck in Pending

```bash
# Check PVC status
kubectl get pvc
kubectl describe pvc <pvc-name>

# Check storage class
kubectl get storageclass
kubectl describe storageclass <class-name>

# Check node capacity
kubectl describe node <node-name> | grep -A 5 "Allocated resources"
```

### Pod Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check previous pod (if exists)
kubectl logs <pod-name> --previous
```

### Data Not Persisting

```bash
# Verify PVC is bound
kubectl get pvc <pvc-name>

# Check mount point
kubectl exec <pod-name> -- df -h

# Check volume mount in pod spec
kubectl get pod <pod-name> -o yaml | grep -A 10 volumeMounts
```

## Next Steps

- Read [STATEFULSET.md](../STATEFULSET.md) for detailed documentation
- Check [MIGRATION-TO-STATEFULSET.md](../MIGRATION-TO-STATEFULSET.md) for migration guide
- Review [statefulset-basic-values.yaml](statefulset-basic-values.yaml) for simple example
- Review [statefulset-multiple-pvcs-values.yaml](statefulset-multiple-pvcs-values.yaml) for advanced example
- Review [statefulset-redis-cluster-values.yaml](statefulset-redis-cluster-values.yaml) for production example

## Tips

1. **Start small**: Begin with 1 replica, verify it works, then scale up
2. **Use labels**: Add labels to PVCs for easy identification
3. **Monitor storage**: Keep an eye on PVC usage
4. **Backup regularly**: Implement backup strategy for persistent data
5. **Test scaling**: Practice scaling operations in dev environment
6. **Use anti-affinity**: Spread pods across nodes for HA
7. **Set resource limits**: Prevent resource exhaustion
8. **Configure probes**: Ensure proper health checking
