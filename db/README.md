# Database Configuration

MySQL database setup for the Producer-Consumer workflow.

## Structure

```
db/
├── mysql-deployment.yaml    # Kubernetes resources
└── schema/
    └── 001_create_batch_tasks.sql
```

## Kubernetes Resources

`mysql-deployment.yaml` includes:

| Resource | Name | Description |
|----------|------|-------------|
| PersistentVolumeClaim | mysql-pvc | 1Gi storage |
| Secret | mysql-credentials | DB credentials |
| Deployment | mysql | MySQL 8.0 container |
| Service | mysql | Exposes port 3306 |

## Credentials

Stored in `mysql-credentials` Secret:

| Key | Value |
|-----|-------|
| database | batch_db |
| username | batch_user |
| password | batch_password |

## Schema

### batch_tasks Table

| Column | Type | Description |
|--------|------|-------------|
| id | BIGINT | Primary key |
| batch_id | VARCHAR(255) | Batch identifier |
| task_data | VARCHAR(1000) | Task payload |
| status | VARCHAR(50) | PENDING, PROCESSED, etc. |
| created_at | TIMESTAMP | Creation time |

## Deployment

```bash
# Deploy MySQL
kubectl apply -f db/mysql-deployment.yaml

# Initialize schema (after MySQL is running)
kubectl exec -it deployment/mysql -- mysql -u batch_user -pbatch_password batch_db < db/schema/001_create_batch_tasks.sql

# Verify
kubectl get pods -l app=mysql
kubectl get svc mysql
```
