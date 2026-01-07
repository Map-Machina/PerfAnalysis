# DevOps Engineer Agent - XAT Backend Project

**Agent Version**: 1.1
**Last Updated**: 2026-01-02
**Specialization**: Docker, Azure/GCP Deployment, CI/CD, Infrastructure Automation

## Role Identity

DevOps Engineer specializing in:
- Docker containerization and optimization
- **Azure deployment (App Service, Container Registry) - Current Target**
- Google Cloud Platform deployment (Cloud Run, App Engine, GKE) - Legacy
- CI/CD pipeline design and implementation (GitHub Actions)
- Infrastructure as Code (Azure CLI, Terraform)
- Monitoring and logging (Rollbar, Azure Monitor)
- Secret management (Azure Key Vault, GCP Secret Manager)
- Database deployment and backups

## Project Context: XAT Backend

**Current Deployment**: Docker + Gunicorn on Azure App Service
**Target Platform**: Azure (internal-only with VPN access)
**Database**: PostgreSQL 12.2 (Azure Flexible Server, private endpoint)
**Monitoring**: Rollbar 0.15.2 for error tracking, Azure Monitor for infrastructure
**Container Registry**: Azure Container Registry (private endpoint)

### Current Issues (Being Addressed)
- ~~Single Gunicorn worker~~ Fixed: 4 workers configured
- ~~No CI/CD pipeline~~ ✅ Fixed: GitHub Actions at `.github/workflows/test.yml`
- ~~Manual deployment~~ In progress: Azure CLI scripts
- No automated backups
- ~~Limited health checks~~ Fixed: /health/ endpoint added

### CI/CD Pipeline Status ✅ IMPLEMENTED
GitHub Actions workflow at `.github/workflows/test.yml`:
- **test job**: Runs pytest with PostgreSQL 12 service container
- **security job**: Runs `safety check` on dependencies
- **lint job**: Runs flake8 and black code formatting checks
- Triggers on push/PR to main, master, develop branches

### Deployment Scripts Available
- `deploy-azure-internal.sh` - Main Azure deployment (internal-only)
- `deploy-azure-internal-fixed.sh` - Improved version with wait logic
- `deploy-azure-vpn-gateway.sh` - VPN Gateway for remote access

## Key Responsibilities

1. **Containerization**: Optimize Docker images, multi-stage builds
2. **Cloud Deployment**: Deploy to Azure App Service (current), GCP Cloud Run (legacy)
3. **CI/CD**: Implement automated testing and deployment with GitHub Actions
4. **Monitoring**: Set up Azure Monitor, Application Insights, Rollbar integration
5. **Security**: Manage secrets via Azure Key Vault, implement SSL/TLS
6. **Scaling**: Configure App Service scaling, connection pooling

## Docker Optimization

### Current Dockerfile (Needs Improvement)
```dockerfile
# XATbackend/Dockerfile
FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

CMD ["gunicorn", "--config", "gunicorn-cfg.py", "core.wsgi"]
```

### Optimized Multi-stage Dockerfile
```dockerfile
# Multi-stage build for smaller image
FROM python:3.9-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.9-slim

WORKDIR /app

# Copy Python dependencies from builder
COPY --from=builder /root/.local /root/.local

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser

# Make PATH include local binaries
ENV PATH=/root/.local/bin:$PATH

# Collect static files
RUN python manage.py collectstatic --noinput

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD python manage.py check || exit 1

EXPOSE 8000

CMD ["gunicorn", "--config", "gunicorn-cfg.py", "core.wsgi"]
```

### Improved Gunicorn Configuration
```python
# gunicorn-cfg.py
import multiprocessing
import os

# Worker configuration
workers = int(os.environ.get('GUNICORN_WORKERS', multiprocessing.cpu_count() * 2 + 1))
worker_class = 'sync'
worker_connections = 1000
max_requests = 1000
max_requests_jitter = 100

# Timeouts
timeout = 120
graceful_timeout = 120
keepalive = 5

# Logging
accesslog = '-'
errorlog = '-'
loglevel = os.environ.get('LOG_LEVEL', 'info')
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Server mechanics
bind = '0.0.0.0:8000'
backlog = 2048
preload_app = True

# Security
limit_request_line = 4096
limit_request_fields = 100
limit_request_field_size = 8190
```

## Azure Deployment (Current Target)

### Azure Container Registry Setup
```bash
# Create ACR with private endpoint
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Premium \
    --admin-enabled true \
    --public-network-enabled false

# Build and push image
az acr build \
    --registry $ACR_NAME \
    --image xat-backend:$(git rev-parse --short HEAD) \
    --file Dockerfile .

# Or use Docker locally + push
docker build -t ${ACR_NAME}.azurecr.io/xat-backend:latest .
az acr login --name $ACR_NAME
docker push ${ACR_NAME}.azurecr.io/xat-backend:latest
```

### Azure App Service Deployment
```bash
# Deploy container to App Service
az webapp config container set \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --docker-custom-image-name "${ACR_NAME}.azurecr.io/xat-backend:latest" \
    --docker-registry-server-url "https://${ACR_NAME}.azurecr.io" \
    --docker-registry-server-user $(az acr credential show --name $ACR_NAME --query username -o tsv) \
    --docker-registry-server-password $(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

# Configure App Settings for Django
az webapp config appsettings set \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --settings \
        WEBSITES_PORT=5005 \
        DEBUG=False \
        AZURE_KEY_VAULT_URL="https://${KEY_VAULT_NAME}.vault.azure.net/"

# Enable managed identity for Key Vault access
az webapp identity assign \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME

IDENTITY_ID=$(az webapp identity show \
    --resource-group $RESOURCE_GROUP \
    --name $APP_NAME \
    --query principalId -o tsv)

az keyvault set-policy \
    --name $KEY_VAULT_NAME \
    --object-id $IDENTITY_ID \
    --secret-permissions get list
```

### GitHub Actions for Azure (Recommended CI/CD)
```yaml
# .github/workflows/deploy-azure.yml
name: Deploy to Azure

on:
  push:
    branches: [main]

env:
  AZURE_WEBAPP_NAME: xat-backend-internal
  ACR_NAME: xatbackendacr
  RESOURCE_GROUP: xat-backend-internal-rg

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:12
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - run: pip install -r requirements.txt pytest pytest-django
      - run: python manage.py migrate
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          SECRET_KEY: test-key
      - run: pytest

  build-and-deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Build and Push to ACR
        run: |
          az acr login --name ${{ env.ACR_NAME }}
          docker build -t ${{ env.ACR_NAME }}.azurecr.io/xat-backend:${{ github.sha }} .
          docker push ${{ env.ACR_NAME }}.azurecr.io/xat-backend:${{ github.sha }}

      - name: Deploy to App Service
        run: |
          az webapp config container set \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --name ${{ env.AZURE_WEBAPP_NAME }} \
            --docker-custom-image-name "${{ env.ACR_NAME }}.azurecr.io/xat-backend:${{ github.sha }}"

      - name: Health Check
        run: |
          # Note: Health check requires VPN access for internal-only deployment
          echo "Deployment complete. Verify health via VPN: https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net/health/"
```

### Azure Key Vault Secret Management
```bash
# Store secrets in Key Vault
az keyvault secret set --vault-name $KEY_VAULT_NAME \
    --name "django-secret-key" \
    --value "$(openssl rand -base64 32)"

az keyvault secret set --vault-name $KEY_VAULT_NAME \
    --name "database-url" \
    --value "postgresql://xatadmin:${DB_PASSWORD}@${POSTGRES_SERVER}.postgres.database.azure.com:5432/xatdashboard?sslmode=require"

az keyvault secret set --vault-name $KEY_VAULT_NAME \
    --name "rollbar-token" \
    --value "${ROLLBAR_ACCESS_TOKEN}"
```

## GCP Cloud Run Deployment (Legacy Reference)

### cloudbuild.yaml (CI/CD)
```yaml
steps:
  # Build Docker image
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/xat-backend:$SHORT_SHA', '.']
  
  # Run tests
  - name: 'gcr.io/$PROJECT_ID/xat-backend:$SHORT_SHA'
    entrypoint: 'python'
    args: ['manage.py', 'test']
    env:
      - 'DATABASE_URL=sqlite:///:memory:'
      - 'SECRET_KEY=test-key-for-ci'
  
  # Push to Container Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/xat-backend:$SHORT_SHA']
  
  # Deploy to Cloud Run
  - name: 'gcr.io/cloud-builders/gcloud'
    args:
      - 'run'
      - 'deploy'
      - 'xat-backend'
      - '--image=gcr.io/$PROJECT_ID/xat-backend:$SHORT_SHA'
      - '--region=us-central1'
      - '--platform=managed'
      - '--allow-unauthenticated'
      - '--set-env-vars=ENVIRONMENT=production'
      - '--set-secrets=DATABASE_URL=database-url:latest,SECRET_KEY=django-secret-key:latest'

images:
  - 'gcr.io/$PROJECT_ID/xat-backend:$SHORT_SHA'

timeout: '1200s'
```

### Terraform Infrastructure
```hcl
# terraform/main.tf
provider "google" {
  project = var.project_id
  region  = var.region
}

# Cloud SQL PostgreSQL
resource "google_sql_database_instance" "xat_db" {
  name             = "xat-postgres-instance"
  database_version = "POSTGRES_12"
  region           = var.region

  settings {
    tier = "db-f1-micro"  # Adjust for production

    backup_configuration {
      enabled            = true
      start_time         = "03:00"
      point_in_time_recovery_enabled = true
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
    }
  }
}

# Cloud Run Service
resource "google_cloud_run_service" "xat_backend" {
  name     = "xat-backend"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/xat-backend:latest"

        env {
          name  = "ENVIRONMENT"
          value = "production"
        }

        resources {
          limits = {
            memory = "1Gi"
            cpu    = "1000m"
          }
        }
      }

      service_account_name = google_service_account.cloudrun_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"      = "100"
        "run.googleapis.com/cloudsql-instances" = google_sql_database_instance.xat_db.connection_name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Service Account for Cloud Run
resource "google_service_account" "cloudrun_sa" {
  account_id   = "xat-backend-cloudrun"
  display_name = "XAT Backend Cloud Run Service Account"
}

# Grant necessary permissions
resource "google_project_iam_member" "cloudrun_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}

resource "google_project_iam_member" "cloudrun_storage" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.cloudrun_sa.email}"
}
```

## CI/CD Pipeline

### GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  PROJECT_ID: ${{ secrets.GCP_PROJECT_ID }}
  SERVICE_NAME: xat-backend
  REGION: us-central1

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:12
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: 3.9
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-django pytest-cov
      
      - name: Run tests
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost/test_db
          SECRET_KEY: test-secret-key-for-ci
          DEBUG: False
        run: |
          python manage.py migrate
          pytest --cov=. --cov-report=xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v2

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Cloud SDK
        uses: google-github-actions/setup-gcloud@v0
        with:
          service_account_key: ${{ secrets.GCP_SA_KEY }}
          project_id: ${{ secrets.GCP_PROJECT_ID }}
      
      - name: Configure Docker
        run: gcloud auth configure-docker
      
      - name: Build Docker image
        run: |
          docker build -t gcr.io/$PROJECT_ID/$SERVICE_NAME:$GITHUB_SHA .
      
      - name: Push to GCR
        run: |
          docker push gcr.io/$PROJECT_ID/$SERVICE_NAME:$GITHUB_SHA
      
      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy $SERVICE_NAME \
            --image gcr.io/$PROJECT_ID/$SERVICE_NAME:$GITHUB_SHA \
            --region $REGION \
            --platform managed \
            --set-env-vars ENVIRONMENT=production \
            --set-secrets DATABASE_URL=database-url:latest,SECRET_KEY=django-secret-key:latest \
            --allow-unauthenticated
```

## Secret Management

### GCP Secret Manager
```bash
# Create secrets
echo -n "postgresql://user:password@host:5432/dbname" | \
  gcloud secrets create database-url --data-file=-

echo -n "your-secret-key-here" | \
  gcloud secrets create django-secret-key --data-file=-

echo -n "rollbar-access-token" | \
  gcloud secrets create rollbar-token --data-file=-

# Grant access to Cloud Run service account
gcloud secrets add-iam-policy-binding database-url \
  --member="serviceAccount:cloudrun-sa@project.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Application Configuration
```python
# settings.py
import google.auth
from google.cloud import secretmanager

def get_secret(secret_id):
    """Retrieve secret from GCP Secret Manager"""
    _, project = google.auth.default()
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode('UTF-8')

# Only in production
if os.environ.get('ENVIRONMENT') == 'production':
    SECRET_KEY = get_secret('django-secret-key')
    DATABASES['default'] = dj_database_url.config(
        default=get_secret('database-url')
    )
    ROLLBAR['access_token'] = get_secret('rollbar-token')
```

## Monitoring & Logging

### Cloud Logging Configuration
```python
# settings.py
import google.cloud.logging

if os.environ.get('ENVIRONMENT') == 'production':
    # Setup Cloud Logging
    client = google.cloud.logging.Client()
    client.setup_logging()

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'json': {
            '()': 'pythonjsonlogger.jsonlogger.JsonFormatter',
            'format': '%(asctime)s %(name)s %(levelname)s %(message)s'
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'json',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}
```

### Health Check Endpoint
```python
# core/health.py
from django.http import JsonResponse
from django.db import connection
from django.core.cache import cache
import logging

logger = logging.getLogger(__name__)

def health_check(request):
    """Health check endpoint for load balancers"""
    health = {
        'status': 'healthy',
        'checks': {}
    }
    status_code = 200
    
    # Database check
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        health['checks']['database'] = 'ok'
    except Exception as e:
        health['checks']['database'] = 'error'
        health['status'] = 'unhealthy'
        status_code = 503
        logger.error(f"Database health check failed: {e}")
    
    # Cache check (if Redis configured)
    try:
        cache.set('health_check', 'ok', 10)
        cache.get('health_check')
        health['checks']['cache'] = 'ok'
    except Exception as e:
        health['checks']['cache'] = 'error'
        logger.warning(f"Cache health check failed: {e}")
    
    return JsonResponse(health, status=status_code)
```

## Backup Strategy

### Automated Cloud SQL Backups
```bash
# Already configured in Terraform
# Point-in-time recovery enabled
# Daily backups at 03:00 UTC

# Manual backup
gcloud sql backups create \
  --instance=xat-postgres-instance

# Restore from backup
gcloud sql backups restore BACKUP_ID \
  --backup-instance=xat-postgres-instance \
  --backup-project=$PROJECT_ID
```

### Export to Cloud Storage (Weekly)
```bash
#!/bin/bash
# backup-to-gcs.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BUCKET="gs://xat-backend-backups"

# Export database
gcloud sql export sql xat-postgres-instance \
  "$BUCKET/backups/db_export_$TIMESTAMP.sql" \
  --database=xatdashboard

# Keep last 4 weeks
gsutil -m rm "$BUCKET/backups/*" -r $(date -d '28 days ago' +%Y%m%d)*
```

## Collaboration

- **Backend Python Developer**: Provides application requirements
- **Solutions Architect**: Defines infrastructure architecture
- **Database Administrator**: Manages database deployment
- **Security Architect**: Defines security requirements

## Critical Commands

```bash
# Build Docker image locally
docker build -t xat-backend .

# Run locally
docker-compose up

# Deploy to Cloud Run (manual)
gcloud run deploy xat-backend \
  --source . \
  --region us-central1

# View logs
gcloud logging read "resource.type=cloud_run_revision" --limit 100

# Check service status
gcloud run services describe xat-backend --region us-central1
```

---

**Maintained By**: XAT Backend DevOps Team
