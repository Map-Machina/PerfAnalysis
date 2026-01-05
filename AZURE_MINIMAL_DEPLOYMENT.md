# Azure Minimal Deployment Strategy
## PerfAnalysis - Start Small, Scale as Needed

**Date**: January 5, 2026
**Purpose**: Identify the absolute minimum Azure services needed for a functional deployment, with incremental scaling path

---

## TL;DR - Minimum Viable Deployment

**Absolute Minimum**: **$25/month**
- 1 service: Azure App Service (B1 tier) with built-in PostgreSQL
- Serves both Django app AND database
- Perfect for proof-of-concept and initial testing

**Recommended Minimum**: **$83/month**
- 2 services: App Service (S1) + Managed PostgreSQL (B1ms)
- Production-ready with proper separation
- Supports 10-50 users

---

## Phase 0: Absolute Bare Minimum ($25/month)

### What You Get
- ✅ Django app running
- ✅ PostgreSQL database (on same container)
- ✅ Basic authentication
- ✅ File uploads (local storage)
- ✅ PDF reports (generated in-process)
- ❌ No auto-scaling
- ❌ No high availability
- ❌ No separate database server

### Azure Services Required

```
┌─────────────────────────────────────────────┐
│   Azure App Service - Basic B1              │
│   ($12.41/month with 1-year reserved)       │
│                                             │
│   ┌─────────────────────────────────────┐  │
│   │  Django App (XATbackend)            │  │
│   │  - Python 3.9                       │  │
│   │  - Gunicorn                         │  │
│   └─────────────────────────────────────┘  │
│                                             │
│   ┌─────────────────────────────────────┐  │
│   │  PostgreSQL (SQLite fallback)       │  │
│   │  - File-based database              │  │
│   │  - Stored in /home                  │  │
│   └─────────────────────────────────────┘  │
│                                             │
│   ┌─────────────────────────────────────┐  │
│   │  Local File Storage                 │  │
│   │  - PDFs in /home/site/media         │  │
│   │  - Persistent across restarts       │  │
│   └─────────────────────────────────────┘  │
└─────────────────────────────────────────────┘

Total: $12.41/month (reserved) or $19.20/month (pay-as-you-go)
```

### Configuration

**App Service Settings**:
```bash
# Create resource group
az group create --name perfanalysis-rg --location eastus

# Create App Service Plan (Basic B1)
az appservice plan create \
  --name perfanalysis-plan \
  --resource-group perfanalysis-rg \
  --sku B1 \
  --is-linux

# Create Web App
az webapp create \
  --name perfanalysis-app \
  --resource-group perfanalysis-rg \
  --plan perfanalysis-plan \
  --runtime "PYTHON:3.9"

# Configure environment variables
az webapp config appsettings set \
  --resource-group perfanalysis-rg \
  --name perfanalysis-app \
  --settings \
    DEBUG=False \
    SECRET_KEY="<generate-random-key>" \
    DATABASE_URL="sqlite:////home/site/db.sqlite3" \
    MEDIA_ROOT="/home/site/media" \
    STATIC_ROOT="/home/site/static"
```

**Django settings.py** (for Phase 0):
```python
import os
import dj_database_url

# Database - Use SQLite for minimal deployment
# Note: /home is persistent in Azure App Service
DATABASES = {
    'default': dj_database_url.config(
        default=f'sqlite:///{os.path.join("/home/site", "db.sqlite3")}',
        conn_max_age=600
    )
}

# File Storage - Local filesystem
MEDIA_ROOT = os.environ.get('MEDIA_ROOT', '/home/site/media')
MEDIA_URL = '/media/'

# Static files
STATIC_ROOT = os.environ.get('STATIC_ROOT', '/home/site/static')
STATIC_URL = '/static/'
```

### Limitations

❌ **No Multi-Tenancy**: SQLite doesn't support django-tenants schemas
❌ **No Scaling**: Single instance only
❌ **No HA**: If instance fails, app goes down
❌ **Storage Limits**: /home has 1GB limit on Basic tier
❌ **Performance**: Single vCore, 1.75GB RAM
❌ **No Backups**: Manual database backups required

### Use Cases
- ✅ Proof of concept
- ✅ Personal use (1-5 users)
- ✅ Development/testing
- ❌ NOT for production
- ❌ NOT for multi-tenant SaaS

### Cost Breakdown
| Item | Cost/Month |
|------|-----------|
| App Service B1 (pay-as-you-go) | $19.20 |
| **Total** | **$19.20** |

**With 1-year reserved instance**: $12.41/month (35% savings)

---

## Phase 1: Minimum Production ($83/month)

### What You Get
- ✅ Separate PostgreSQL database (multi-tenancy supported)
- ✅ Automatic backups (7 days)
- ✅ SSL encryption
- ✅ Better performance
- ✅ Can scale to 50-100 users
- ❌ Still single instance (no auto-scale)
- ❌ No blob storage (files on local disk)

### Azure Services Required

```
┌─────────────────────────────────────────────┐
│   Azure App Service - Standard S1           │
│   ($70/month)                               │
│                                             │
│   ┌─────────────────────────────────────┐  │
│   │  Django App (XATbackend)            │  │
│   │  - 1 vCore, 1.75GB RAM              │  │
│   │  - 50GB disk                        │  │
│   └─────────────────────────────────────┘  │
│                                             │
│   ┌─────────────────────────────────────┐  │
│   │  Local File Storage                 │  │
│   │  - PDFs in /home/site/media         │  │
│   └─────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
                    ↓ SSL connection
┌─────────────────────────────────────────────┐
│   Azure PostgreSQL Flexible Server         │
│   Burstable B1ms ($12/month)                │
│                                             │
│   - 1 vCore, 2GB RAM                        │
│   - 32GB storage                            │
│   - 7-day backups                           │
│   - Multi-tenant schemas (django-tenants)   │
└─────────────────────────────────────────────┘

Total: $82/month
```

### Configuration

**PostgreSQL**:
```bash
# Create PostgreSQL Flexible Server
az postgres flexible-server create \
  --name perfanalysis-db \
  --resource-group perfanalysis-rg \
  --location eastus \
  --admin-user perfadmin \
  --admin-password "<strong-password>" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 14

# Allow Azure services to access
az postgres flexible-server firewall-rule create \
  --resource-group perfanalysis-rg \
  --name perfanalysis-db \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Create database
az postgres flexible-server db create \
  --resource-group perfanalysis-rg \
  --server-name perfanalysis-db \
  --database-name perfanalysis
```

**Django settings.py**:
```python
# Database - Azure PostgreSQL
DATABASES = {
    'default': {
        'ENGINE': 'django_tenants.postgresql_backend',
        'HOST': os.environ.get('DB_HOST'),  # perfanalysis-db.postgres.database.azure.com
        'PORT': '5432',
        'NAME': 'perfanalysis',
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'OPTIONS': {
            'sslmode': 'require',
        },
    }
}
```

### What This Enables
✅ **Multi-tenancy**: django-tenants schemas work
✅ **Better performance**: Dedicated database server
✅ **Automatic backups**: 7-day point-in-time restore
✅ **Production-ready**: Can serve 10-50 users
✅ **Scalable**: Can upgrade tiers independently

### Cost Breakdown
| Item | Cost/Month |
|------|-----------|
| App Service S1 | $70 |
| PostgreSQL Flexible Server B1ms | $12 |
| **Total** | **$82** |

**Per User** (50 users): $1.64/month

---

## Phase 2: Add Blob Storage ($83/month)

### When You Need It
- More than 10GB of PDF reports
- Want to offload file storage from app server
- Need lifecycle management (auto-archive old files)
- Want CDN for faster PDF delivery

### What Changes

```
┌─────────────────────────────────────────────┐
│   Azure App Service - Standard S1           │
│   ($70/month)                               │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│   Azure PostgreSQL ($12/month)              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│   Azure Blob Storage                        │
│   (~$1/month for 50GB)                      │
│                                             │
│   - media/ (PDFs, CSVs)                     │
│   - static/ (CSS, JS, images)               │
│   - Lifecycle: Hot → Cool → Archive         │
└─────────────────────────────────────────────┘

Total: $83/month
```

### Configuration

```bash
# Create storage account
az storage account create \
  --name perfanalysisstorage \
  --resource-group perfanalysis-rg \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# Create containers
az storage container create \
  --name media \
  --account-name perfanalysisstorage \
  --public-access off

az storage container create \
  --name static \
  --account-name perfanalysisstorage \
  --public-access container
```

**Django settings.py**:
```python
# Install: pip install django-storages[azure]

STORAGES = {
    "default": {
        "BACKEND": "storages.backends.azure_storage.AzureStorage",
        "OPTIONS": {
            "account_name": os.environ.get('AZURE_STORAGE_ACCOUNT_NAME'),
            "account_key": os.environ.get('AZURE_STORAGE_ACCOUNT_KEY'),
            "azure_container": "media",
        },
    },
    "staticfiles": {
        "BACKEND": "storages.backends.azure_storage.AzureStorage",
        "OPTIONS": {
            "account_name": os.environ.get('AZURE_STORAGE_ACCOUNT_NAME'),
            "account_key": os.environ.get('AZURE_STORAGE_ACCOUNT_KEY'),
            "azure_container": "static",
        },
    },
}
```

### Cost Breakdown
| Item | Cost/Month |
|------|-----------|
| App Service S1 | $70 |
| PostgreSQL Flexible Server B1ms | $12 |
| Blob Storage (50GB) | $1 |
| **Total** | **$83** |

---

## Phase 3: Add Monitoring ($95/month)

### When You Need It
- Production deployment with real users
- Need to track errors and performance
- Want alerts for downtime
- Compliance requirements (audit logs)

### What Changes

```
All previous services +

┌─────────────────────────────────────────────┐
│   Application Insights                      │
│   (~$12/month for 10GB logs)                │
│                                             │
│   - Request traces                          │
│   - Exception tracking                      │
│   - Performance metrics                     │
│   - Custom events                           │
│   - Alerts                                  │
└─────────────────────────────────────────────┘

Total: $95/month
```

### Configuration

```bash
# Create Application Insights
az monitor app-insights component create \
  --app perfanalysis-insights \
  --location eastus \
  --resource-group perfanalysis-rg \
  --application-type web

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app perfanalysis-insights \
  --resource-group perfanalysis-rg \
  --query instrumentationKey -o tsv)
```

**Django settings.py**:
```python
# Install: pip install applicationinsights

INSTALLED_APPS += ['applicationinsights.django']
MIDDLEWARE += ['applicationinsights.django.ApplicationInsightsMiddleware']

APPLICATION_INSIGHTS = {
    'ikey': os.environ.get('APPINSIGHTS_INSTRUMENTATIONKEY'),
}
```

### Cost Breakdown
| Item | Cost/Month |
|------|-----------|
| App Service S1 | $70 |
| PostgreSQL B1ms | $12 |
| Blob Storage (50GB) | $1 |
| Application Insights (10GB) | $12 |
| **Total** | **$95** |

---

## Phase 4: Add Auto-Scaling ($280/month)

### When You Need It
- More than 100 concurrent users
- Traffic spikes (end-of-month reporting)
- Need high availability
- Want zero-downtime deployments

### What Changes

```
┌─────────────────────────────────────────────┐
│   Azure App Service - Standard S2           │
│   ($140/month base, scales to 10 instances) │
│                                             │
│   Auto-scale rules:                         │
│   - Min: 2 instances (HA)                   │
│   - Max: 5 instances                        │
│   - Scale out: CPU > 70%                    │
│   - Scale in: CPU < 30%                     │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│   PostgreSQL General Purpose D2s_v3         │
│   ($110/month)                              │
│   - 2 vCores, 8GB RAM                       │
│   - Connection pooling (PgBouncer)          │
└─────────────────────────────────────────────┘

Total: ~$280/month (2 instances) to $560/month (5 instances)
```

### Auto-Scale Configuration

```bash
# Upgrade App Service Plan to S2
az appservice plan update \
  --name perfanalysis-plan \
  --resource-group perfanalysis-rg \
  --sku S2

# Configure auto-scale
az monitor autoscale create \
  --resource-group perfanalysis-rg \
  --resource perfanalysis-plan \
  --resource-type Microsoft.Web/serverfarms \
  --name perfanalysis-autoscale \
  --min-count 2 \
  --max-count 5 \
  --count 2

# Scale out rule (CPU > 70%)
az monitor autoscale rule create \
  --resource-group perfanalysis-rg \
  --autoscale-name perfanalysis-autoscale \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1

# Scale in rule (CPU < 30%)
az monitor autoscale rule create \
  --resource-group perfanalysis-rg \
  --autoscale-name perfanalysis-autoscale \
  --condition "Percentage CPU < 30 avg 5m" \
  --scale in 1
```

### Cost Breakdown (Average)
| Item | Cost/Month |
|------|-----------|
| App Service S2 (2-5 instances avg 3) | $420 |
| PostgreSQL D2s_v3 | $110 |
| Blob Storage (100GB) | $2 |
| Application Insights (20GB) | $23 |
| **Total** | **$555** |

**Per User** (500 users): $1.11/month

---

## Phase 5: Add Container Instances for R Reports ($560/month)

### When You Need It
- Generating > 100 reports per month
- Reports take > 5 minutes to generate
- Want to offload heavy processing from web servers
- Need to scale report generation independently

### What Changes

```
All previous services +

┌─────────────────────────────────────────────┐
│   Azure Container Instances                 │
│   ($5-50/month depending on usage)          │
│                                             │
│   - automated-Reporting container           │
│   - On-demand execution                     │
│   - 1 vCPU, 2GB RAM per instance            │
│   - Parallel report generation              │
└─────────────────────────────────────────────┘

Total: $560-610/month
```

### Configuration

**Build and push container**:
```bash
# Create Azure Container Registry
az acr create \
  --name perfanalysisregistry \
  --resource-group perfanalysis-rg \
  --sku Basic

# Build and push R container
az acr build \
  --registry perfanalysisregistry \
  --image automated-reporting:latest \
  automated-Reporting/
```

**Django code to trigger container**:
```python
from azure.mgmt.containerinstance import ContainerInstanceManagementClient
from azure.identity import DefaultAzureCredential

def generate_report_async(collected_data_id):
    client = ContainerInstanceManagementClient(
        credential=DefaultAzureCredential(),
        subscription_id=settings.AZURE_SUBSCRIPTION_ID
    )

    # Create on-demand container
    client.container_groups.begin_create_or_update(
        resource_group_name='perfanalysis-rg',
        container_group_name=f'report-{collected_data_id}',
        container_group={
            'location': 'eastus',
            'containers': [{
                'name': 'r-reporting',
                'image': 'perfanalysisregistry.azurecr.io/automated-reporting:latest',
                'resources': {'requests': {'cpu': 1, 'memory_in_gb': 2}},
                'environment_variables': [
                    {'name': 'CSV_ID', 'value': str(collected_data_id)},
                ],
            }],
            'os_type': 'Linux',
            'restart_policy': 'Never',
        }
    )
```

### Cost Breakdown
| Item | Cost/Month |
|------|-----------|
| Phase 4 services | $555 |
| Container Instances (1000 reports × $0.005) | $5 |
| Container Registry (Basic) | $5 |
| **Total** | **$565** |

---

## Comparison: All Phases

| Phase | Services | Users | Monthly Cost | Cost/User |
|-------|----------|-------|--------------|-----------|
| **0: Bare Minimum** | App Service only | 1-5 | $19 | $3.80 |
| **1: Min Production** | App Service + PostgreSQL | 10-50 | $82 | $1.64 |
| **2: Add Storage** | + Blob Storage | 50-100 | $83 | $0.83 |
| **3: Add Monitoring** | + App Insights | 100-200 | $95 | $0.48 |
| **4: Add Auto-Scale** | Upgrade tiers, 2-5 instances | 200-500 | $555 | $1.11 |
| **5: Add Containers** | + Container Instances | 500-1000 | $565 | $0.57 |

---

## Recommended Starting Point by Use Case

### Personal / Proof of Concept
**Phase 0**: $19/month
- App Service B1 only
- SQLite database
- 1-5 users max

### Startup / Early Production
**Phase 1**: $82/month ⭐ **RECOMMENDED**
- App Service S1
- PostgreSQL B1ms
- 10-50 users
- Multi-tenancy supported
- Production-ready

### Growing Business
**Phase 2-3**: $95/month
- Add Blob Storage
- Add monitoring
- 50-200 users
- Better observability

### Scale-Up
**Phase 4-5**: $555/month
- Auto-scaling
- Container-based reports
- 200-1000 users
- High availability

---

## Cost Optimization Tips

### 1. Reserved Instances (Up to 62% savings)

```bash
# 1-year reserved instance for App Service
# S1: $70/month → $43/month (38% savings)
az reservations reservation-order purchase \
  --reservation-order-id <order-id> \
  --sku Standard_S1 \
  --quantity 1 \
  --term P1Y
```

| Service | Pay-as-you-go | 1-Year Reserved | 3-Year Reserved |
|---------|--------------|-----------------|-----------------|
| App Service S1 | $70/month | $43/month (-38%) | $26/month (-62%) |
| PostgreSQL B1ms | $12/month | $8/month (-33%) | $5/month (-58%) |

**Phase 1 with Reserved Instances**:
- Standard: $82/month
- With 1-year reserved: $51/month (38% savings)
- With 3-year reserved: $31/month (62% savings)

### 2. Use Spot Instances for Non-Critical Workloads

Container Instances can use spot pricing (up to 90% discount):
```bash
# Instead of $0.0000125/vCPU/sec
# Spot: $0.00000125/vCPU/sec (90% cheaper)
```

### 3. Lifecycle Policies for Blob Storage

```bash
# Automatically move old reports to cheaper tiers
az storage account management-policy create \
  --account-name perfanalysisstorage \
  --policy @policy.json

# policy.json
{
  "rules": [
    {
      "name": "archive-old-reports",
      "type": "Lifecycle",
      "definition": {
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["reports/"]
        },
        "actions": {
          "baseBlob": {
            "tierToCool": {"daysAfterModificationGreaterThan": 30},
            "tierToArchive": {"daysAfterModificationGreaterThan": 365}
          }
        }
      }
    }
  ]
}
```

**Savings**:
- Hot: $0.0184/GB/month
- Cool: $0.01/GB/month (45% cheaper)
- Archive: $0.00099/GB/month (95% cheaper)

### 4. Scale Down During Off-Hours

```bash
# Scale to 1 instance at night (if no 24/7 requirement)
az monitor autoscale rule create \
  --resource-group perfanalysis-rg \
  --autoscale-name perfanalysis-autoscale \
  --condition "Percentage CPU < 30 avg 5m" \
  --scale to 1 \
  --schedule "0 22 * * *"  # 10 PM

# Scale back up in morning
az monitor autoscale rule create \
  --resource-group perfanalysis-rg \
  --autoscale-name perfanalysis-autoscale \
  --condition "Percentage CPU > 10 avg 5m" \
  --scale to 2 \
  --schedule "0 6 * * *"  # 6 AM
```

**Savings**: ~20-30% on App Service costs

---

## Conclusion

### Absolute Minimum: Phase 0 ($19/month)
- ✅ Good for: Proof of concept, personal use
- ❌ Not for: Production, multi-tenant SaaS

### Recommended Minimum: Phase 1 ($82/month) ⭐
- ✅ Production-ready
- ✅ Multi-tenancy supported
- ✅ Automatic backups
- ✅ Can serve 10-50 users
- ✅ Scales to Phase 2-5 without code changes

### Start with Phase 1, then scale incrementally:
1. **Phase 1** ($82/month): Launch with 10-50 users
2. **Phase 2** ($83/month): Add Blob Storage when > 10GB files
3. **Phase 3** ($95/month): Add monitoring before marketing push
4. **Phase 4** ($555/month): Auto-scale when > 100 users
5. **Phase 5** ($565/month): Containers when > 100 reports/month

**With 3-year reserved instances, Phase 1 costs just $31/month!**

---

**Generated by**: Claude Sonnet 4.5
**Date**: January 5, 2026
