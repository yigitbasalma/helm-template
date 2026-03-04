# Jobs Support

This document describes how to use Kubernetes Jobs with the base-helm-template.

## Overview

Jobs are one-time tasks that run to completion. Unlike Deployments or StatefulSets that run continuously, Jobs execute a task and then terminate. They're perfect for:

- Database migrations
- Data imports/exports
- Backup operations
- Initialization tasks
- Batch processing
- One-off administrative tasks

## Basic Configuration

Add jobs to your `values.yaml`:

```yaml
jobs:
  - name: database-migration
    image: "myapp/migrations:1.0.0"
    command: ["/bin/sh", "-c"]
    args:
      - "./migrate.sh up"
    env:
      DATABASE_URL: "postgresql://postgres:5432/mydb"
    backoffLimit: 3
    restartPolicy: OnFailure
```

## Configuration Parameters

### Required Parameters

- `name`: Job name (will be prefixed with release name)
- `image`: Container image to run

### Optional Parameters

#### Job Behavior
- `backoffLimit`: Number of retries before marking job as failed (default: 6)
- `restartPolicy`: Pod restart policy - `OnFailure` or `Never` (default: OnFailure)
- `activeDeadlineSeconds`: Maximum time job can run before termination
- `ttlSecondsAfterFinished`: Automatic cleanup after completion (in seconds)

#### Container Configuration
- `command`: Container command (array)
- `args`: Container arguments (array)
- `imagePullPolicy`: Image pull policy (IfNotPresent, Always, Never)

#### Environment Variables
- `env`: Environment variables (map or array format)

#### Resources
- `resources`: CPU and memory limits/requests

#### Storage
- `volumeMounts`: Volume mount points
- `volumes`: Volumes to attach

#### Scheduling
- `serviceAccountName`: Service account for the job
- `nodeSelector`: Node selection constraints
- `tolerations`: Pod tolerations
- `affinity`: Pod affinity/anti-affinity rules

#### Metadata
- `labels`: Additional labels for the Job
- `annotations`: Additional annotations for the Job

## Examples

### 1. Simple Database Migration

```yaml
jobs:
  - name: db-migrate
    image: "myapp/migrations:1.0.0"
    command: ["/bin/sh", "-c"]
    args:
      - "./migrate.sh up"
    env:
      DATABASE_URL: "postgresql://postgres:5432/mydb"
    backoffLimit: 3
    restartPolicy: OnFailure
    activeDeadlineSeconds: 600  # 10 minutes
    ttlSecondsAfterFinished: 86400  # Clean up after 24 hours
```

### 2. Data Import with Volume

```yaml
jobs:
  - name: data-import
    image: "myapp/importer:latest"
    command: ["/app/import.sh"]
    args:
      - "--source=/data/import.csv"
      - "--target=postgresql://db:5432/mydb"
    backoffLimit: 5
    restartPolicy: Never
    volumeMounts:
      - name: import-data
        mountPath: /data
    volumes:
      - name: import-data
        persistentVolumeClaim:
          claimName: import-data-pvc
```

### 3. Backup Job with Secrets

```yaml
jobs:
  - name: backup
    image: "postgres:15-alpine"
    command: ["/bin/sh", "-c"]
    args:
      - |
        pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME > /backup/backup-$(date +%Y%m%d-%H%M%S).sql
    env:
      - name: DB_HOST
        value: "postgres-service"
      - name: DB_USER
        valueFrom:
          secretKeyRef:
            name: db-credentials
            key: username
      - name: PGPASSWORD
        valueFrom:
          secretKeyRef:
            name: db-credentials
            key: password
      - name: DB_NAME
        value: "production"
    volumeMounts:
      - name: backup-storage
        mountPath: /backup
    volumes:
      - name: backup-storage
        persistentVolumeClaim:
          claimName: backup-pvc
```

### 4. Initialization Job

```yaml
jobs:
  - name: app-init
    image: "myapp/init:latest"
    command: ["/app/init.sh"]
    args:
      - "--setup-database"
      - "--create-admin-user"
      - "--load-fixtures"
    env:
      APP_ENV: "production"
    serviceAccountName: "init-sa"
    backoffLimit: 1
    restartPolicy: Never
    activeDeadlineSeconds: 300
    ttlSecondsAfterFinished: 600
```

### 5. Job with Node Selection

```yaml
jobs:
  - name: heavy-processing
    image: "myapp/processor:latest"
    command: ["/app/process.sh"]
    resources:
      limits:
        cpu: "4000m"
        memory: "8Gi"
      requests:
        cpu: "2000m"
        memory: "4Gi"
    nodeSelector:
      workload: batch
      node-size: large
    tolerations:
      - key: "batch"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
```

## Environment Variables

Jobs support two formats for environment variables:

### Map Format (Simple)

```yaml
jobs:
  - name: my-job
    env:
      DATABASE_URL: "postgresql://db:5432/mydb"
      LOG_LEVEL: "info"
```

### Array Format (Advanced)

```yaml
jobs:
  - name: my-job
    env:
      - name: DATABASE_URL
        value: "postgresql://db:5432/mydb"
      - name: DB_PASSWORD
        valueFrom:
          secretKeyRef:
            name: db-credentials
            key: password
      - name: CONFIG_FILE
        valueFrom:
          configMapKeyRef:
            name: app-config
            key: config.yaml
```

## Job Lifecycle

### Restart Policies

- `OnFailure`: Restart the pod if it fails (recommended for most cases)
- `Never`: Don't restart the pod, create a new pod instead

### Backoff Limit

Controls how many times Kubernetes will retry a failed job:

```yaml
backoffLimit: 3  # Retry up to 3 times
```

### Active Deadline

Maximum time a job can run before being terminated:

```yaml
activeDeadlineSeconds: 600  # 10 minutes
```

### TTL After Finished

Automatically clean up completed jobs:

```yaml
ttlSecondsAfterFinished: 86400  # Delete after 24 hours
```

## Best Practices

### 1. Set Appropriate Timeouts

Always set `activeDeadlineSeconds` to prevent jobs from running indefinitely:

```yaml
activeDeadlineSeconds: 1800  # 30 minutes
```

### 2. Enable Automatic Cleanup

Use `ttlSecondsAfterFinished` to automatically clean up completed jobs:

```yaml
ttlSecondsAfterFinished: 86400  # 24 hours
```

### 3. Use Appropriate Restart Policy

- Use `OnFailure` for transient failures (network issues, temporary unavailability)
- Use `Never` for jobs that shouldn't retry (data imports that might duplicate data)

### 4. Set Resource Limits

Always define resource limits to prevent resource exhaustion:

```yaml
resources:
  limits:
    cpu: "1000m"
    memory: "1Gi"
  requests:
    cpu: "500m"
    memory: "512Mi"
```

### 5. Use Service Accounts

Create dedicated service accounts with minimal permissions:

```yaml
serviceAccountName: "migration-sa"
```

### 6. Monitor Job Status

Check job status regularly:

```bash
kubectl get jobs
kubectl describe job <job-name>
kubectl logs job/<job-name>
```

## Troubleshooting

### Job Not Starting

Check pod status:
```bash
kubectl get pods -l job-name=<job-name>
kubectl describe pod <pod-name>
```

### Job Failing Repeatedly

Check logs:
```bash
kubectl logs job/<job-name>
kubectl logs job/<job-name> --previous  # Previous attempt
```

### Job Stuck

Check if activeDeadlineSeconds is set:
```bash
kubectl describe job <job-name>
```

### Cleanup Not Working

Verify TTL controller is enabled in your cluster:
```bash
kubectl get pods -n kube-system | grep ttl
```

## Comparison: Jobs vs CronJobs

| Feature | Jobs | CronJobs |
|---------|------|----------|
| Execution | One-time | Scheduled/Recurring |
| Schedule | Manual/Helm install | Cron expression |
| Use Case | Migrations, imports | Backups, cleanup |
| Cleanup | TTL-based | History limits |

## Generated Resource Names

Jobs are named using the pattern: `{release-name}-{job-name}`

Example:
- Release: `myapp`
- Job name: `database-migration`
- Generated name: `myapp-database-migration`

## Complete Example

See [examples/jobs-values.yaml](examples/jobs-values.yaml) for comprehensive examples including:
- Database migrations
- Data imports
- Backup operations
- Initialization tasks
- Cleanup jobs
- Jobs with node affinity

## Related Documentation

- [CronJobs](README.md#cronjobs) - For scheduled/recurring tasks
- [StatefulSet](STATEFULSET.md) - For stateful applications
- [ConfigMaps](CONFIGMAPS.md) - For configuration management
- [Multiple PVCs](MULTIPLE-PVCS.md) - For persistent storage
