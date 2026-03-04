# Migration Guide: Deployment to StatefulSet

This guide helps you migrate an existing Deployment to a StatefulSet using this Helm chart.

## Prerequisites

- Backup your data before migration
- Understand that migration requires downtime
- Have access to your current values.yaml
- Ensure your storage class supports dynamic provisioning

## Migration Steps

### Step 1: Backup Current Configuration

```bash
# Export current values
helm get values <release-name> > current-values.yaml

# Backup current deployment
kubectl get deployment <deployment-name> -o yaml > deployment-backup.yaml

# Backup data if using PVCs
kubectl get pvc -l app.kubernetes.io/instance=<release-name> -o yaml > pvc-backup.yaml
```

### Step 2: Prepare StatefulSet Values

Create a new values file based on your current configuration:

```yaml
# Change workload type
workloadType: statefulset

# Keep existing configuration
replicaCount: 3
image:
  repository: your-app
  tag: "1.0.0"

# Add StatefulSet volume claim templates
statefulset:
  volumeClaimTemplates:
    - name: data
      accessModes:
        - ReadWriteOnce
      storage: 10Gi
      storageClassName: fast-ssd

# Configure volume mounts
volumeMounts:
  - name: data
    mountPath: /var/lib/app/data

# Add pod anti-affinity (recommended)
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

### Step 3: Data Migration Strategy

Choose one of these strategies based on your needs:

#### Strategy A: Fresh Start (No Data Migration)

Best for: Development environments, stateless apps, or when data can be regenerated

```bash
# Uninstall current deployment
helm uninstall <release-name>

# Delete old PVCs if any
kubectl delete pvc -l app.kubernetes.io/instance=<release-name>

# Install as StatefulSet
helm install <release-name> . -f statefulset-values.yaml
```

#### Strategy B: Manual Data Copy (Recommended)

Best for: Production environments with critical data

```bash
# Step 1: Scale down deployment to 1 replica
kubectl scale deployment <deployment-name> --replicas=1

# Step 2: Create a backup pod with access to old PVC
kubectl run backup-pod --image=busybox --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "backup",
      "image": "busybox",
      "command": ["sleep", "3600"],
      "volumeMounts": [{
        "name": "data",
        "mountPath": "/old-data"
      }]
    }],
    "volumes": [{
      "name": "data",
      "persistentVolumeClaim": {
        "claimName": "<old-pvc-name>"
      }
    }]
  }
}'

# Step 3: Copy data to external storage or backup
kubectl exec backup-pod -- tar czf /tmp/backup.tar.gz /old-data
kubectl cp backup-pod:/tmp/backup.tar.gz ./backup.tar.gz

# Step 4: Uninstall deployment
helm uninstall <release-name>

# Step 5: Install StatefulSet
helm install <release-name> . -f statefulset-values.yaml

# Step 6: Wait for StatefulSet to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=<release-name> --timeout=300s

# Step 7: Restore data to new StatefulSet pods
for i in 0 1 2; do
  kubectl cp ./backup.tar.gz <release-name>-$i:/tmp/backup.tar.gz
  kubectl exec <release-name>-$i -- tar xzf /tmp/backup.tar.gz -C /
done

# Step 8: Cleanup
kubectl delete pod backup-pod
rm backup.tar.gz
```

#### Strategy C: Storage Migration with PV Reuse

Best for: When you want to reuse existing PersistentVolumes

```bash
# Step 1: Get PV details
kubectl get pv

# Step 2: Change PV reclaim policy to Retain
kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

# Step 3: Uninstall deployment
helm uninstall <release-name>

# Step 4: Delete PVC (PV will be retained)
kubectl delete pvc <old-pvc-name>

# Step 5: Remove claimRef from PV to make it available
kubectl patch pv <pv-name> --type json -p '[{"op": "remove", "path": "/spec/claimRef"}]'

# Step 6: Create StatefulSet values with volumeName to bind to existing PV
cat > statefulset-values.yaml <<EOF
workloadType: statefulset
replicaCount: 1  # Start with 1 to bind to existing PV

statefulset:
  volumeClaimTemplates:
    - name: data
      accessModes:
        - ReadWriteOnce
      storage: 10Gi
      storageClassName: fast-ssd
      volumeName: <pv-name>  # Bind to existing PV
EOF

# Step 7: Install StatefulSet
helm install <release-name> . -f statefulset-values.yaml

# Step 8: Verify data is accessible
kubectl exec <release-name>-0 -- ls -la /var/lib/app/data

# Step 9: Scale up if needed
kubectl scale statefulset <release-name> --replicas=3
```

### Step 4: Verify Migration

```bash
# Check StatefulSet status
kubectl get statefulset
kubectl describe statefulset <release-name>

# Check pods
kubectl get pods -l app.kubernetes.io/instance=<release-name>

# Check PVCs
kubectl get pvc -l app.kubernetes.io/instance=<release-name>

# Verify data
kubectl exec <release-name>-0 -- ls -la /var/lib/app/data

# Check application logs
kubectl logs <release-name>-0

# Test application functionality
kubectl port-forward <release-name>-0 8080:80
curl http://localhost:8080
```

### Step 5: Update DNS/Service References

If your application uses pod-specific DNS:

```bash
# Old Deployment pod DNS (random)
<pod-name>.<namespace>.svc.cluster.local

# New StatefulSet pod DNS (stable)
<release-name>-0.<release-name>.<namespace>.svc.cluster.local
<release-name>-1.<release-name>.<namespace>.svc.cluster.local
<release-name>-2.<release-name>.<namespace>.svc.cluster.local
```

Update any hardcoded references in your application or configuration.

## Common Issues and Solutions

### Issue 1: PVC Stuck in Pending

**Symptom**: PVC remains in Pending state

**Solution**:
```bash
# Check PVC events
kubectl describe pvc <pvc-name>

# Common causes:
# - No storage class available
# - Insufficient storage capacity
# - Storage class doesn't support dynamic provisioning

# Fix: Ensure storage class exists and has capacity
kubectl get storageclass
```

### Issue 2: Pods Not Starting

**Symptom**: Pods stuck in ContainerCreating or Pending

**Solution**:
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check if PVC is bound
kubectl get pvc

# Check node resources
kubectl describe node <node-name>
```

### Issue 3: Data Not Accessible

**Symptom**: Application can't find data after migration

**Solution**:
```bash
# Verify mount path
kubectl exec <pod-name> -- df -h

# Check file permissions
kubectl exec <pod-name> -- ls -la /var/lib/app/data

# Fix permissions if needed
kubectl exec <pod-name> -- chown -R app:app /var/lib/app/data
```

### Issue 4: Scaling Issues

**Symptom**: StatefulSet doesn't scale properly

**Solution**:
```bash
# Check StatefulSet status
kubectl get statefulset <name> -o yaml

# Check if previous pod is ready
kubectl get pods -l app.kubernetes.io/instance=<release-name>

# StatefulSets scale sequentially - ensure each pod is Ready before next starts
```

## Rollback Plan

If migration fails, rollback to Deployment:

```bash
# Step 1: Backup StatefulSet data if needed
kubectl exec <release-name>-0 -- tar czf /tmp/backup.tar.gz /var/lib/app/data
kubectl cp <release-name>-0:/tmp/backup.tar.gz ./backup.tar.gz

# Step 2: Uninstall StatefulSet
helm uninstall <release-name>

# Step 3: Restore original Deployment
helm install <release-name> . -f current-values.yaml

# Step 4: Restore data if needed
kubectl cp ./backup.tar.gz <pod-name>:/tmp/backup.tar.gz
kubectl exec <pod-name> -- tar xzf /tmp/backup.tar.gz -C /
```

## Best Practices

1. **Always backup data** before migration
2. **Test migration** in non-production environment first
3. **Plan for downtime** - migration requires stopping the application
4. **Use pod anti-affinity** to spread replicas across nodes
5. **Monitor resource usage** after migration
6. **Document the process** for your team
7. **Keep old PVs** for a few days as backup (set reclaim policy to Retain)
8. **Verify application functionality** thoroughly after migration

## Post-Migration Checklist

- [ ] All pods are running and ready
- [ ] All PVCs are bound
- [ ] Data is accessible and correct
- [ ] Application functionality works as expected
- [ ] Monitoring and alerts are configured
- [ ] Backup strategy is in place
- [ ] Documentation is updated
- [ ] Team is informed about new pod naming scheme
- [ ] Old resources are cleaned up (after verification period)

## Additional Resources

- [StatefulSet Documentation](STATEFULSET.md)
- [Kubernetes StatefulSet Concepts](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Multiple PVCs Guide](MULTIPLE-PVCS.md)
- [Examples](examples/)
