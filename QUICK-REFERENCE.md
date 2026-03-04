# Quick Reference: StatefulSet vs Deployment

## Choosing Workload Type

```yaml
# Deployment (default) - for stateless apps
workloadType: deployment

# StatefulSet - for stateful apps
workloadType: statefulset
```

## When to Use What

| Use Deployment | Use StatefulSet |
|----------------|-----------------|
| Web servers | Databases |
| API services | Distributed systems |
| Stateless apps | Caching clusters |
| Microservices | Message queues |
| No persistent data | Persistent data per pod |

## Basic Configurations

### Minimal Deployment
```yaml
workloadType: deployment
replicaCount: 3
image:
  repository: nginx
  tag: "1.21"
service:
  port: 80
```

### Minimal StatefulSet
```yaml
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
      storage: 10Gi
      storageClassName: standard
volumeMounts:
  - name: data
    mountPath: /data
```

## Storage Options

### Shared PVC (Both Workload Types)
```yaml
multiplePVCs:
  - name: shared-data
    accessModes:
      - ReadWriteMany
    storage: 10Gi
    storageClassName: nfs

volumes:
  - name: shared-data
    persistentVolumeClaim:
      claimName: shared-data

volumeMounts:
  - name: shared-data
    mountPath: /shared
```

### Per-Pod PVC (StatefulSet Only)
```yaml
statefulset:
  volumeClaimTemplates:
    - name: data
      accessModes:
        - ReadWriteOnce
      storage: 10Gi
      storageClassName: fast-ssd

volumeMounts:
  - name: data
    mountPath: /data
```

## Command and Args

```yaml
# Just command
command:
  - /bin/sh
  - -c
  - "echo Hello && sleep 3600"

# Command with args
command:
  - redis-server
args:
  - --cluster-enabled
  - "yes"
  - --appendonly
  - "yes"
```

## Common Patterns

### Database (PostgreSQL)
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
volumeMounts:
  - name: data
    mountPath: /var/lib/postgresql/data
```

### Cache (Redis)
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
statefulset:
  volumeClaimTemplates:
    - name: data
      storage: 10Gi
      storageClassName: fast-ssd
volumeMounts:
  - name: data
    mountPath: /data
```

### Web App (Nginx)
```yaml
workloadType: deployment
replicaCount: 3
image:
  repository: nginx
  tag: "1.21"
service:
  port: 80
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

## Pod Anti-Affinity

### Required (Hard)
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

### Preferred (Soft)
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

## Common Commands

### Install
```bash
# Deployment
helm install myapp . --set workloadType=deployment

# StatefulSet
helm install myapp . -f examples/statefulset-basic-values.yaml
```

### Upgrade
```bash
helm upgrade myapp . --set image.tag=2.0.0
```

### Scale
```bash
# Deployment (parallel)
kubectl scale deployment myapp --replicas=5

# StatefulSet (sequential)
kubectl scale statefulset myapp --replicas=5
```

### Check Status
```bash
# Deployment
kubectl get deployment
kubectl describe deployment myapp

# StatefulSet
kubectl get statefulset
kubectl describe statefulset myapp

# PVCs
kubectl get pvc
kubectl describe pvc data-myapp-0
```

### Delete
```bash
# Uninstall
helm uninstall myapp

# Delete PVCs (StatefulSet - not automatic)
kubectl delete pvc -l app.kubernetes.io/instance=myapp
```

## Troubleshooting

### PVC Stuck in Pending
```bash
kubectl describe pvc <pvc-name>
kubectl get storageclass
```

### Pod Not Starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Check Resources
```bash
kubectl get all -l app.kubernetes.io/instance=myapp
kubectl get pvc -l app.kubernetes.io/instance=myapp
kubectl get configmap -l app.kubernetes.io/instance=myapp
```

## Access Patterns

### Deployment
```bash
# Service (round-robin)
kubectl port-forward svc/myapp 8080:80

# Specific pod (random name)
kubectl exec -it myapp-7d8f9c5b6-x7k2m -- /bin/bash
```

### StatefulSet
```bash
# Service (round-robin)
kubectl port-forward svc/myapp 8080:80

# Specific pod (stable name)
kubectl exec -it myapp-0 -- /bin/bash
kubectl exec -it myapp-1 -- /bin/bash

# Pod DNS
myapp-0.myapp.default.svc.cluster.local
myapp-1.myapp.default.svc.cluster.local
```

## Storage Classes

```yaml
# Fast SSD
storageClassName: fast-ssd

# Standard HDD
storageClassName: standard

# Network storage
storageClassName: nfs

# Local storage
storageClassName: local-storage
```

## Access Modes

```yaml
# Single node read-write
accessModes:
  - ReadWriteOnce

# Multiple nodes read-write
accessModes:
  - ReadWriteMany

# Multiple nodes read-only
accessModes:
  - ReadOnlyMany
```

## Examples

```bash
# Basic StatefulSet
helm install test . -f examples/statefulset-basic-values.yaml

# Database with multiple volumes
helm install postgres . -f examples/statefulset-multiple-pvcs-values.yaml

# Redis cluster
helm install redis . -f examples/statefulset-redis-cluster-values.yaml

# Complete example
helm install complete . -f examples/complete-statefulset-example.yaml
```

## Documentation

- [STATEFULSET.md](STATEFULSET.md) - Full guide
- [MIGRATION-TO-STATEFULSET.md](MIGRATION-TO-STATEFULSET.md) - Migration
- [examples/statefulset-quickstart.md](examples/statefulset-quickstart.md) - Quick start
- [examples/README.md](examples/README.md) - Examples
