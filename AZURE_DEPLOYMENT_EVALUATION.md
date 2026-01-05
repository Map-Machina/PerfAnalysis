# Microsoft Azure Deployment Stack Evaluation
## PerfAnalysis Ecosystem

**Date**: January 5, 2026
**Evaluator**: Claude Sonnet 4.5
**Purpose**: Evaluate Azure as deployment platform for PerfAnalysis multi-component system

---

## Executive Summary

**Recommendation**: **Azure App Service + Azure Database for PostgreSQL is highly suitable** for PerfAnalysis deployment, especially for enterprise customers.

**Key Benefits**:
- ✅ Managed PostgreSQL with built-in multi-tenancy support
- ✅ Django App Service deployment with minimal configuration changes
- ✅ Azure AD integration for enterprise SSO
- ✅ Auto-scaling for performance analysis workloads
- ✅ Built-in monitoring and diagnostics
- ✅ Cost-effective for small to medium deployments

**Best For**:
- Enterprise customers requiring compliance (SOC2, HIPAA, ISO27001)
- Multi-tenant SaaS deployment
- Teams already using Microsoft ecosystem
- Organizations needing SSO with Azure AD/Entra ID

---

## Current PerfAnalysis Architecture

### Components
```
┌─────────────────────────────────────────────────────────┐
│ perfcollector2 (Go)                                     │
│  - Collects /proc metrics from Linux servers            │
│  - HTTP POST to XATbackend                              │
│  - Deployed on target servers                           │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼ HTTP POST (CSV data)
┌─────────────────────────────────────────────────────────┐
│ XATbackend (Django 3.2.3 + Python 3.9)                  │
│  - Multi-tenant user portal                             │
│  - Collector management                                 │
│  - Data storage (PostgreSQL)                            │
│  - Analysis orchestration                               │
│  - Serves PDF reports                                   │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼ CSV export
┌─────────────────────────────────────────────────────────┐
│ automated-Reporting (R + TinyTeX)                       │
│  - R markdown templates (reporting.Rmd)                 │
│  - PDF generation with ggplot2 visualizations           │
│  - 68 visualization chunks                              │
│  - Statistical analysis (quantiles, percentiles)        │
└─────────────────────────────────────────────────────────┘
                        │
                        ▼ PDF output
┌─────────────────────────────────────────────────────────┐
│ Dash003 (Shiny R) - Optional                            │
│  - Interactive Plotly dashboards                        │
│  - Real-time visualization                              │
│  - Radar charts, time series                            │
└─────────────────────────────────────────────────────────┘
```

### Current Deployment (Assumed)
- **Local/Docker**: Development environment
- **Target**: Enterprise deployment (healthcare, finance)
- **Scale**: Multi-tenant (multiple organizations)
- **Database**: PostgreSQL with django-tenants

---

## Azure Services Mapping

### 1. XATbackend (Django) → Azure App Service

**Service**: Azure App Service (Linux, Python 3.9+)

**Configuration**:
```yaml
# azure-webapp-config.yml
runtime:
  name: python
  version: "3.9"

startup_command: gunicorn --bind=0.0.0.0:8000 core.wsgi:application

app_settings:
  - name: WEBSITES_PORT
    value: "8000"
  - name: DJANGO_SETTINGS_MODULE
    value: "core.settings"
  - name: DATABASE_URL
    value: "@Microsoft.KeyVault(SecretUri=https://perfanalysis-kv.vault.azure.net/secrets/db-url)"
  - name: SECRET_KEY
    value: "@Microsoft.KeyVault(SecretUri=https://perfanalysis-kv.vault.azure.net/secrets/django-secret)"
```

**Features**:
- ✅ Auto-scaling (scale out to 10+ instances)
- ✅ Deployment slots (staging/production)
- ✅ SSL/TLS certificates (free with custom domains)
- ✅ Managed identity for secure secrets
- ✅ Application Insights integration
- ✅ GitHub Actions CI/CD

**Pricing (Example)**:
- **Basic (B1)**: $13/month - Dev/Test
- **Standard (S1)**: $70/month - Production
- **Premium (P1v3)**: $124/month - High performance

**Pros**:
- Django is first-class citizen on App Service
- Automatic OS patching and updates
- Built-in load balancing
- Easy SSL setup

**Cons**:
- Windows-based App Service less mature for Python
- Resource limitations on lower tiers
- Cannot customize underlying infrastructure

---

### 2. PostgreSQL Database → Azure Database for PostgreSQL

**Service**: Azure Database for PostgreSQL - Flexible Server

**Configuration**:
```hcl
# Terraform example
resource "azurerm_postgresql_flexible_server" "perfanalysis" {
  name                   = "perfanalysis-db"
  resource_group_name    = azurerm_resource_group.perfanalysis.name
  location              = "East US"
  version               = "14"

  administrator_login    = "perfadmin"
  administrator_password = "<from-key-vault>"

  sku_name = "GP_Standard_D2s_v3"  # 2 vCores, 8GB RAM

  storage_mb = 32768  # 32GB

  backup_retention_days = 35
  geo_redundant_backup_enabled = true

  high_availability {
    mode = "ZoneRedundant"
  }
}

resource "azurerm_postgresql_flexible_server_database" "perfanalysis" {
  name      = "perfanalysis"
  server_id = azurerm_postgresql_flexible_server.perfanalysis.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Connection pooling
resource "azurerm_postgresql_flexible_server_configuration" "pgbouncer" {
  name      = "pgbouncer.enabled"
  server_id = azurerm_postgresql_flexible_server.perfanalysis.id
  value     = "true"
}
```

**Features**:
- ✅ Automatic backups (35 days retention)
- ✅ Point-in-time restore
- ✅ High availability (99.99% SLA with zone redundancy)
- ✅ Built-in monitoring
- ✅ Automatic minor version upgrades
- ✅ PgBouncer connection pooling
- ✅ Read replicas for analytics

**Pricing (Flexible Server)**:
| Tier | vCores | RAM | Storage | Price/Month |
|------|--------|-----|---------|-------------|
| Burstable (B1ms) | 1 | 2GB | 32GB | ~$12 |
| General Purpose (D2s_v3) | 2 | 8GB | 128GB | ~$110 |
| General Purpose (D4s_v3) | 4 | 16GB | 256GB | ~$220 |
| Memory Optimized (E2s_v3) | 2 | 16GB | 128GB | ~$165 |

**Multi-Tenancy Support**:
```python
# Django-tenants works seamlessly with Azure PostgreSQL
DATABASES = {
    'default': {
        'ENGINE': 'django_tenants.postgresql_backend',
        'HOST': os.environ.get('DB_HOST'),  # perfanalysis-db.postgres.database.azure.com
        'PORT': '5432',
        'NAME': 'perfanalysis',
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'OPTIONS': {
            'sslmode': 'require',  # Azure requires SSL
        },
    }
}
```

**Pros**:
- Fully managed (no server maintenance)
- Excellent performance for time-series data
- Built-in HA and disaster recovery
- Supports all PostgreSQL extensions (including django-tenants schema separation)

**Cons**:
- More expensive than self-hosted
- Limited customization of PostgreSQL config
- SSL required (slight overhead)

---

### 3. Blob Storage for Reports → Azure Blob Storage

**Service**: Azure Blob Storage (Hot tier)

**Use Cases**:
- PDF reports from automated-Reporting
- CSV uploads from perfcollector2
- Static files (CSS, JS, images)

**Configuration**:
```python
# Django settings.py
AZURE_ACCOUNT_NAME = os.environ.get('AZURE_STORAGE_ACCOUNT_NAME')
AZURE_ACCOUNT_KEY = os.environ.get('AZURE_STORAGE_ACCOUNT_KEY')
AZURE_CONTAINER = 'media'

STORAGES = {
    "default": {
        "BACKEND": "storages.backends.azure_storage.AzureStorage",
        "OPTIONS": {
            "account_name": AZURE_ACCOUNT_NAME,
            "account_key": AZURE_ACCOUNT_KEY,
            "azure_container": AZURE_CONTAINER,
        },
    },
    "staticfiles": {
        "BACKEND": "storages.backends.azure_storage.AzureStorage",
        "OPTIONS": {
            "account_name": AZURE_ACCOUNT_NAME,
            "account_key": AZURE_ACCOUNT_KEY,
            "azure_container": "static",
        },
    },
}
```

**Features**:
- ✅ 99.999999999% (11 9's) durability
- ✅ Lifecycle management (auto-archive old reports)
- ✅ CDN integration for static files
- ✅ Immutable storage (compliance)
- ✅ Soft delete (recovery)

**Pricing**:
- **Hot tier**: $0.0184/GB/month (first 50TB)
- **Cool tier**: $0.01/GB/month (reports older than 30 days)
- **Archive tier**: $0.00099/GB/month (reports older than 1 year)

**Example Cost** (100 users, 10 reports/user/month, 171KB/report):
- Storage: 100 × 10 × 0.171MB × 12 months = 2GB/year
- Cost: $0.04/month (negligible)

**Pros**:
- Extremely cheap for PDF storage
- Automatic lifecycle policies
- Built-in CDN for faster PDF delivery
- Integrates with Django storage backends

**Cons**:
- Requires code changes from local filesystem
- Download costs (though minimal for PDFs)

---

### 4. automated-Reporting (R) → Azure Container Instances

**Service**: Azure Container Instances (ACI)

**Why ACI**:
- R + TinyTeX is containerized
- On-demand execution (not 24/7 server)
- Pay only when generating reports
- Fast cold start (< 60 seconds)

**Configuration**:
```yaml
# docker-compose-azure.yml
services:
  r-reporting:
    image: perfanalysis.azurecr.io/automated-reporting:latest
    environment:
      - INPUT_CSV_URL=${BLOB_STORAGE_CSV_URL}
      - OUTPUT_BLOB_CONTAINER=reports
      - AZURE_STORAGE_ACCOUNT=${AZURE_STORAGE_ACCOUNT}
    volumes:
      - /mnt/azure/reports:/output
```

**Deployment** (via Django job):
```python
# In Django view
from azure.mgmt.containerinstance import ContainerInstanceManagementClient
from azure.identity import DefaultAzureCredential

def generate_report(collected_data_id):
    client = ContainerInstanceManagementClient(
        credential=DefaultAzureCredential(),
        subscription_id=settings.AZURE_SUBSCRIPTION_ID
    )

    # Create container instance
    container = client.container_groups.begin_create_or_update(
        resource_group_name='perfanalysis-rg',
        container_group_name=f'report-{collected_data_id}',
        container_group={
            'location': 'eastus',
            'containers': [{
                'name': 'r-reporting',
                'image': 'perfanalysis.azurecr.io/automated-reporting:latest',
                'resources': {'requests': {'cpu': 1, 'memory_in_gb': 2}},
                'environment_variables': [
                    {'name': 'CSV_URL', 'value': get_csv_url(collected_data_id)},
                    {'name': 'OUTPUT_CONTAINER', 'value': 'reports'},
                ],
            }],
            'os_type': 'Linux',
            'restart_policy': 'Never',
        }
    )

    return container.result()
```

**Pricing**:
- **CPU**: $0.0000125/vCPU/second
- **Memory**: $0.0000014/GB/second
- **Example**: 1 vCPU, 2GB RAM, 5 min report = $0.005/report

**Pros**:
- Pay only for actual report generation time
- No idle server costs
- Auto-scales to handle multiple concurrent reports
- Simple container deployment

**Cons**:
- Cold start time (~60 seconds)
- More complex than App Service
- Requires container orchestration code

**Alternative**: Azure Container Apps (serverless, better for background jobs)

---

### 5. Dash003 (Shiny R) → Azure Container Instances or App Service

**Option A**: Azure Container Instances (Same as automated-Reporting)
- Good for testing/demo
- Pay-per-use model
- Not ideal for production dashboard

**Option B**: Azure App Service for Containers
```yaml
# Dockerfile for Shiny
FROM rocker/shiny:latest
RUN R -e "install.packages(c('shinydashboard', 'plotly', 'DT'))"
COPY app.R /srv/shiny-server/
EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
```

**Pricing**:
- Same as XATbackend App Service
- Can run on same plan (multi-container support)

**Recommendation**:
- **Short-term**: Keep Shiny on ACI for demos
- **Long-term**: Rebuild as Django + Plotly.js (see DASH003_ARCHITECTURE_REVIEW.md)

---

### 6. Key Vault for Secrets → Azure Key Vault

**Service**: Azure Key Vault

**Secrets to Store**:
- Database connection string
- Django SECRET_KEY
- Azure Storage account keys
- Third-party API keys (if any)

**Configuration**:
```python
# settings.py
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

def get_secret(secret_name):
    credential = DefaultAzureCredential()
    client = SecretClient(
        vault_url=f"https://{settings.KEY_VAULT_NAME}.vault.azure.net",
        credential=credential
    )
    return client.get_secret(secret_name).value

# Use in settings
SECRET_KEY = get_secret('django-secret-key')
DATABASES['default']['PASSWORD'] = get_secret('db-password')
```

**Features**:
- ✅ Automatic secret rotation
- ✅ Access logging and auditing
- ✅ RBAC for secret access
- ✅ Soft delete and purge protection

**Pricing**:
- **Standard**: $0.03/10,000 operations
- **Premium** (HSM-backed): $1/key/month

**Pros**:
- Centralized secret management
- Integrates with App Service (no code needed)
- Audit trail for compliance

---

### 7. Monitoring → Azure Application Insights

**Service**: Application Insights (part of Azure Monitor)

**Features**:
- ✅ Django middleware integration
- ✅ Automatic exception tracking
- ✅ Performance metrics (response times, DB queries)
- ✅ Custom events and metrics
- ✅ Dependency tracking (PostgreSQL, Blob Storage calls)
- ✅ Log aggregation

**Configuration**:
```python
# settings.py
INSTALLED_APPS += ['applicationinsights.django']

MIDDLEWARE += ['applicationinsights.django.ApplicationInsightsMiddleware']

APPLICATION_INSIGHTS = {
    'ikey': os.environ.get('APPINSIGHTS_INSTRUMENTATIONKEY'),
    'endpoint': 'https://eastus-8.in.applicationinsights.azure.com/',
    'use_view_name': True,
    'record_view_arguments': True,
}
```

**Built-in Metrics**:
- Request rate, response time, failure rate
- Database query performance
- Blob storage latency
- Custom: Report generation time, collector upload success rate

**Pricing**:
- **First 5GB/month**: Free
- **Additional data**: $2.30/GB

**Typical Usage** (100 users, moderate traffic):
- ~500MB/month = Free tier

**Pros**:
- Deep Django integration
- Powerful query language (Kusto/KQL)
- Smart detection (anomaly detection)
- Integration with Azure alerts

---

### 8. perfcollector2 Deployment → VM Scale Sets or Kubernetes

**Challenge**: perfcollector2 runs on target Linux servers (customers' infrastructure)

**Azure Options**:

#### Option A: Customer Self-Hosted (Recommended)
```bash
# On customer's Linux servers
curl -O https://perfanalysis.blob.core.windows.net/binaries/perfcollector2
chmod +x perfcollector2
./perfcollector2 --endpoint https://perfanalysis.azurewebsites.net/collectors/upload/
```

**Authentication**:
- Azure AD Service Principal (for enterprise customers)
- API key (for smaller deployments)

#### Option B: Azure Arc for Hybrid Servers
```bash
# Install Azure Arc agent on customer servers
azcmagent connect \
  --resource-group "perfanalysis-rg" \
  --tenant-id "<tenant-id>" \
  --subscription-id "<subscription-id>"

# Deploy perfcollector2 via Azure Policy
az policy assignment create \
  --name "deploy-perfcollector" \
  --policy "/providers/Microsoft.Authorization/policyDefinitions/..." \
  --scope "/subscriptions/<subscription-id>"
```

**Benefits**:
- Centralized management of remote collectors
- Automatic updates via Azure Update Management
- Compliance reporting

**Cons**:
- Requires customer to install Azure Arc
- Additional cost (~$5/server/month)

---

## Complete Azure Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Customer's Infrastructure                         │
│                                                                           │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐                │
│  │ Linux Server │   │ Linux Server │   │ Linux Server │                │
│  │              │   │              │   │              │                │
│  │ perfcollector│   │ perfcollector│   │ perfcollector│                │
│  │      2       │   │      2       │   │      2       │                │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘                │
│         │                  │                  │                         │
└─────────┼──────────────────┼──────────────────┼─────────────────────────┘
          │                  │                  │
          │ HTTPS POST (CSV) │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          Azure Cloud                                     │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Azure Front Door (WAF)                        │   │
│  │  - DDoS protection                                               │   │
│  │  - SSL termination                                               │   │
│  │  - Rate limiting                                                 │   │
│  └─────────────────────────┬───────────────────────────────────────┘   │
│                            │                                             │
│                            ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │              Azure App Service (Linux, Python 3.9)               │   │
│  │                    XATbackend Django Portal                      │   │
│  │                                                                   │   │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐       │   │
│  │  │   Instance 1  │  │   Instance 2  │  │   Instance 3  │       │   │
│  │  │  (auto-scale) │  │  (auto-scale) │  │  (auto-scale) │       │   │
│  │  └───────────────┘  └───────────────┘  └───────────────┘       │   │
│  │                                                                   │   │
│  │  Features:                                                        │   │
│  │  - /collectors/upload/ (receive CSV from perfcollector2)         │   │
│  │  - /collectors/manage/ (UI)                                      │   │
│  │  - /analysis/list/ (view reports)                                │   │
│  │  - /dashboard/ (interactive Plotly.js charts)                    │   │
│  │                                                                   │   │
│  │  Deployment: GitHub Actions CI/CD                                │   │
│  │  Slots: Staging, Production                                      │   │
│  └─────────────────────────┬─────────────────────────────────────────┘ │
│                            │                                             │
│         ┌──────────────────┼──────────────────┐                         │
│         ▼                  ▼                  ▼                         │
│  ┌─────────────┐  ┌──────────────────┐  ┌─────────────┐               │
│  │   Azure     │  │    Azure DB for  │  │   Azure     │               │
│  │   Blob      │  │    PostgreSQL    │  │   Key       │               │
│  │   Storage   │  │   (Flexible)     │  │   Vault     │               │
│  │             │  │                  │  │             │               │
│  │ Containers: │  │ - perfanalysis   │  │ Secrets:    │               │
│  │ - media     │  │ - Multi-tenant   │  │ - DB pass   │               │
│  │ - static    │  │ - schemas        │  │ - SECRET_KEY│               │
│  │ - reports   │  │                  │  │ - API keys  │               │
│  └─────────────┘  │ Features:        │  └─────────────┘               │
│                    │ - Auto backup    │                                 │
│                    │ - HA (99.99%)    │                                 │
│                    │ - Read replicas  │                                 │
│                    └──────────────────┘                                 │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │         Azure Container Instances (On-Demand)                    │   │
│  │                                                                   │   │
│  │  ┌──────────────────────────────────────────────────────────┐   │   │
│  │  │  automated-Reporting Container                            │   │   │
│  │  │  - R 4.5.2 + TinyTeX                                      │   │   │
│  │  │  - reporting.Rmd template                                 │   │   │
│  │  │  - Input: CSV from Blob Storage                           │   │   │
│  │  │  - Output: PDF to Blob Storage                            │   │   │
│  │  │  - Lifecycle: Create → Run (5 min) → Delete               │   │   │
│  │  └──────────────────────────────────────────────────────────┘   │   │
│  │                                                                   │   │
│  │  Triggered by: Django celery task or Queue message              │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │         Azure Monitor / Application Insights                     │   │
│  │  - Request traces                                                │   │
│  │  - Database query performance                                    │   │
│  │  - Exception tracking                                            │   │
│  │  - Custom metrics (report generation time, upload success rate) │   │
│  │  - Alerts (error rate, slow queries)                             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │              Azure Active Directory (Entra ID)                   │   │
│  │  - SSO for enterprise customers                                  │   │
│  │  - RBAC (Admin, Analyst, Viewer)                                 │   │
│  │  - Multi-factor authentication                                   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## Cost Analysis

### Scenario 1: Small Deployment (10 users, 50 collectors)

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| App Service | Standard S1 (1 instance) | $70 |
| PostgreSQL | Burstable B1ms (1 vCore, 2GB RAM) | $12 |
| Blob Storage | 5GB (reports + CSV) | $0.10 |
| Key Vault | Standard tier | $0.03 |
| Application Insights | <5GB logs/month | Free |
| Container Instances | ~100 reports/month × $0.005 | $0.50 |
| **Total** | | **~$83/month** |

**Per User**: $8.30/month

---

### Scenario 2: Medium Deployment (100 users, 500 collectors)

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| App Service | Standard S2 (2 instances, auto-scale) | $280 |
| PostgreSQL | General Purpose D2s_v3 (2 vCore, 8GB) | $110 |
| Blob Storage | 50GB | $1.00 |
| Key Vault | Standard tier | $0.03 |
| Application Insights | 10GB logs/month | $11.50 |
| Container Instances | ~1,000 reports/month × $0.005 | $5 |
| **Total** | | **~$408/month** |

**Per User**: $4.08/month

---

### Scenario 3: Enterprise Deployment (1,000 users, 5,000 collectors)

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| App Service | Premium P2v3 (4 instances, auto-scale) | $992 |
| PostgreSQL | General Purpose D4s_v3 (4 vCore, 16GB, HA) | $440 |
| Blob Storage | 500GB | $10 |
| Key Vault | Standard tier | $0.03 |
| Application Insights | 50GB logs/month | $103.50 |
| Container Instances | ~10,000 reports/month × $0.005 | $50 |
| Azure Front Door | Standard tier + WAF | $300 |
| **Total** | | **~$1,896/month** |

**Per User**: $1.90/month

---

### Cost Optimization Strategies

1. **Reserved Instances**:
   - 1-year commitment: 38% discount
   - 3-year commitment: 62% discount
   - Example: S2 App Service = $182/month (was $280)

2. **Azure Hybrid Benefit**:
   - If customer has Windows Server licenses
   - Up to 40% savings on compute

3. **Dev/Test Pricing**:
   - Separate subscription for development
   - Up to 50% discount

4. **Lifecycle Policies**:
   - Move reports >30 days to Cool tier ($0.01/GB vs $0.0184/GB)
   - Archive reports >1 year ($0.00099/GB)

5. **Auto-Scaling**:
   - Scale down during off-hours
   - Example: 2 instances during business hours, 1 instance at night
   - Savings: ~20-30%

---

## Security & Compliance

### Built-in Azure Security

1. **Network Security**:
   - Virtual Network (VNet) integration
   - Private endpoints for database (no public internet exposure)
   - Network Security Groups (NSG) for firewall rules

2. **Data Encryption**:
   - **At rest**: Transparent Data Encryption (TDE) for PostgreSQL
   - **In transit**: TLS 1.2+ required for all connections
   - **Key management**: Azure Key Vault

3. **Identity & Access**:
   - Managed Identity for App Service → Database (no passwords in code)
   - Azure AD authentication for PostgreSQL
   - RBAC for resource access

4. **Compliance Certifications**:
   - ✅ SOC 1/2/3
   - ✅ ISO 27001, 27018, 27701
   - ✅ HIPAA BAA available
   - ✅ PCI DSS Level 1
   - ✅ FedRAMP (Government)

### Security Configuration Example

```python
# settings.py - Azure Security Best Practices

# 1. Use Managed Identity (no passwords)
from azure.identity import DefaultAzureCredential

DATABASES = {
    'default': {
        'ENGINE': 'django_tenants.postgresql_backend',
        'HOST': os.environ.get('DB_HOST'),
        'PORT': '5432',
        'NAME': 'perfanalysis',
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': get_secret('db-password'),  # From Key Vault
        'OPTIONS': {
            'sslmode': 'require',
            'sslrootcert': '/etc/ssl/certs/ca-certificates.crt',
        },
    }
}

# 2. Force HTTPS
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# 3. Security headers
SECURE_HSTS_SECONDS = 31536000  # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# 4. Content Security Policy
CSP_DEFAULT_SRC = ("'self'", "blob:")
CSP_SCRIPT_SRC = ("'self'", "https://cdn.jsdelivr.net")
CSP_STYLE_SRC = ("'self'", "https://fonts.googleapis.com")

# 5. Azure AD SSO (for enterprise)
AUTHENTICATION_BACKENDS = [
    'django.contrib.auth.backends.ModelBackend',
    'azure_ad_auth.backends.AzureADBackend',
]

AZURE_AD = {
    'TENANT_ID': os.environ.get('AZURE_AD_TENANT_ID'),
    'CLIENT_ID': os.environ.get('AZURE_AD_CLIENT_ID'),
    'CLIENT_SECRET': get_secret('azure-ad-client-secret'),
}
```

---

## Deployment Strategy

### CI/CD with GitHub Actions

```yaml
# .github/workflows/azure-deploy.yml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.9'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          python manage.py collectstatic --no-input

      - name: Run tests
        run: |
          pytest
          python manage.py check --deploy

      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy to staging slot
        uses: azure/webapps-deploy@v2
        with:
          app-name: 'perfanalysis-app'
          slot-name: 'staging'
          package: .

      - name: Run smoke tests on staging
        run: |
          curl https://perfanalysis-app-staging.azurewebsites.net/health/

      - name: Swap staging to production
        run: |
          az webapp deployment slot swap \
            --resource-group perfanalysis-rg \
            --name perfanalysis-app \
            --slot staging \
            --target-slot production
```

### Database Migration Strategy

```bash
# Run migrations before deployment (zero-downtime)
az webapp ssh --resource-group perfanalysis-rg --name perfanalysis-app

# Inside container
python manage.py migrate --no-input
python manage.py migrate_schemas --shared  # For django-tenants
```

### Rollback Plan

```bash
# If deployment fails, swap back to previous slot
az webapp deployment slot swap \
  --resource-group perfanalysis-rg \
  --name perfanalysis-app \
  --slot production \
  --target-slot staging
```

---

## Azure vs. Self-Hosted Comparison

| Factor | Azure | Self-Hosted (AWS/DO/DigitalOcean) |
|--------|-------|-----------------------------------|
| **Setup Time** | 1-2 days | 1-2 weeks |
| **Maintenance** | Managed (auto-patching) | Manual (weekly updates) |
| **Scalability** | Auto-scale (instant) | Manual (provision servers) |
| **High Availability** | Built-in (99.95-99.99%) | Manual (load balancer, replicas) |
| **Security** | Enterprise-grade (SOC2, HIPAA) | DIY (requires security expertise) |
| **Monitoring** | Application Insights (built-in) | Need to set up (Datadog, Prometheus) |
| **Backups** | Automatic (35 days) | Manual (cron jobs, S3) |
| **SSL Certificates** | Free (auto-renewal) | Let's Encrypt (manual setup) |
| **Cost (100 users)** | $408/month | $200-300/month |
| **Cost (1000 users)** | $1,896/month | $800-1,200/month |
| **Hidden Costs** | None | DevOps time, monitoring tools |
| **Compliance** | Pre-certified | Need own audits |

**Verdict**:
- **Azure wins** for: Enterprise customers, compliance needs, fast time-to-market
- **Self-hosted wins** for: Cost-sensitive deployments, full control, no vendor lock-in

---

## Integration with Existing Code

### Changes Required for Azure Deployment

#### 1. Database Connection
```python
# Before (local)
DATABASES = {
    'default': {
        'ENGINE': 'django_tenants.postgresql_backend',
        'NAME': 'perfanalysis',
        'USER': 'postgres',
        'PASSWORD': 'postgres',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# After (Azure)
DATABASES = {
    'default': {
        'ENGINE': 'django_tenants.postgresql_backend',
        'NAME': 'perfanalysis',
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': get_secret('db-password'),  # From Key Vault
        'HOST': os.environ.get('DB_HOST'),  # *.postgres.database.azure.com
        'PORT': '5432',
        'OPTIONS': {
            'sslmode': 'require',  # Azure requires SSL
        },
    }
}
```

#### 2. File Storage
```python
# Install django-storages[azure]
pip install django-storages[azure]

# settings.py
STORAGES = {
    "default": {
        "BACKEND": "storages.backends.azure_storage.AzureStorage",
        "OPTIONS": {
            "account_name": os.environ.get('AZURE_STORAGE_ACCOUNT_NAME'),
            "account_key": get_secret('storage-account-key'),
            "azure_container": "media",
        },
    },
}
```

#### 3. Static Files (CDN)
```python
STORAGES = {
    "staticfiles": {
        "BACKEND": "storages.backends.azure_storage.AzureStorage",
        "OPTIONS": {
            "account_name": os.environ.get('AZURE_STORAGE_ACCOUNT_NAME'),
            "account_key": get_secret('storage-account-key'),
            "azure_container": "static",
            "custom_domain": "perfanalysis.azureedge.net",  # CDN
        },
    },
}
```

#### 4. Logging
```python
# settings.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'appinsights': {
            'class': 'applicationinsights.django.LoggingHandler',
            'level': 'INFO',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['appinsights'],
            'level': 'INFO',
        },
    },
}
```

#### 5. Environment Variables
```bash
# .env (local development)
DEBUG=True
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=postgres

# Azure App Service Configuration (portal or CLI)
az webapp config appsettings set \
  --resource-group perfanalysis-rg \
  --name perfanalysis-app \
  --settings \
    DEBUG=False \
    DB_HOST=perfanalysis-db.postgres.database.azure.com \
    DB_USER=perfadmin \
    DB_PASSWORD=@Microsoft.KeyVault(SecretUri=https://perfanalysis-kv.vault.azure.net/secrets/db-password)
```

---

## Recommendations

### ✅ Use Azure If:

1. **Enterprise Customers**:
   - Need SOC2/HIPAA compliance certification
   - Require Azure AD SSO integration
   - Already using Microsoft 365/Teams

2. **Fast Time-to-Market**:
   - Want to deploy in days, not weeks
   - Limited DevOps expertise in-house
   - Need managed services (less maintenance)

3. **Healthcare/Finance Sectors**:
   - Strict compliance requirements
   - Need BAA (Business Associate Agreement) for HIPAA
   - Audit trails and access logging

4. **Scalability Needs**:
   - Expecting rapid growth
   - Variable traffic (auto-scaling saves cost)
   - Global deployment (Azure has 60+ regions)

### ⚠️ Avoid Azure If:

1. **Cost is Primary Concern**:
   - Small deployment (< 50 users)
   - Predictable, stable traffic
   - Self-hosted can be 40-50% cheaper

2. **Vendor Lock-In Concerns**:
   - Want multi-cloud strategy
   - Prefer open-source tools
   - Need Kubernetes/containerized approach

3. **Full Infrastructure Control**:
   - Need custom kernel modules
   - Require specific OS configurations
   - Want bare metal performance

---

## Migration Checklist

### Phase 1: Azure Setup (Week 1)
- [ ] Create Azure account and subscription
- [ ] Set up Resource Group (`perfanalysis-rg`)
- [ ] Create PostgreSQL Flexible Server
- [ ] Create Blob Storage account
- [ ] Create Key Vault
- [ ] Create App Service plan

### Phase 2: Database Migration (Week 2)
- [ ] Export local PostgreSQL database
- [ ] Import to Azure PostgreSQL
- [ ] Verify django-tenants schemas
- [ ] Test connections from local machine
- [ ] Configure SSL certificates

### Phase 3: Code Changes (Week 3)
- [ ] Install `django-storages[azure]`
- [ ] Update `settings.py` for Azure
- [ ] Implement Key Vault secret retrieval
- [ ] Configure Application Insights
- [ ] Update file upload handlers for Blob Storage

### Phase 4: CI/CD Setup (Week 4)
- [ ] Create GitHub Actions workflow
- [ ] Configure Azure credentials in GitHub secrets
- [ ] Set up staging and production slots
- [ ] Configure automated testing
- [ ] Set up rollback procedures

### Phase 5: Container Images (Week 5)
- [ ] Build automated-Reporting Docker image
- [ ] Push to Azure Container Registry
- [ ] Create Azure Container Instance template
- [ ] Test report generation from Django

### Phase 6: Testing (Week 6)
- [ ] End-to-end testing on Azure staging
- [ ] Performance testing (load test with 100 concurrent users)
- [ ] Security testing (penetration test)
- [ ] Disaster recovery test (restore from backup)

### Phase 7: Production Deployment (Week 7)
- [ ] DNS cutover to Azure Front Door
- [ ] Monitor Application Insights for errors
- [ ] Set up alerts (error rate, latency)
- [ ] Update perfcollector2 endpoints
- [ ] Document runbooks for operations

### Phase 8: Optimization (Week 8)
- [ ] Enable CDN for static files
- [ ] Configure auto-scaling rules
- [ ] Set up lifecycle policies for Blob Storage
- [ ] Implement caching (Redis if needed)
- [ ] Cost analysis and optimization

---

## Conclusion

**Azure is an excellent deployment platform for PerfAnalysis**, particularly for enterprise customers requiring:
- Compliance certifications (SOC2, HIPAA, ISO27001)
- Azure AD SSO integration
- Managed infrastructure with minimal DevOps overhead
- Auto-scaling and high availability
- Fast time-to-market

**Cost**: $83/month (10 users) to $1,896/month (1,000 users), with 38-62% discounts via Reserved Instances.

**Recommended Azure Services**:
1. ✅ **Azure App Service** (Django)
2. ✅ **Azure Database for PostgreSQL - Flexible Server**
3. ✅ **Azure Blob Storage** (reports, CSV files)
4. ✅ **Azure Container Instances** (R report generation)
5. ✅ **Azure Key Vault** (secrets)
6. ✅ **Application Insights** (monitoring)

**Migration Time**: 6-8 weeks for full production deployment with testing.

---

**Generated by**: Claude Sonnet 4.5
**Date**: January 5, 2026
**Review Status**: Ready for stakeholder review
