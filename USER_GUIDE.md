# PerfAnalysis User Guide

Complete guide for using the PerfAnalysis integrated performance monitoring system.

## Table of Contents

1. [Introduction](#introduction)
2. [Quick Start](#quick-start)
3. [System Architecture](#system-architecture)
4. [perfcollector2: Data Collection](#perfcollector2-data-collection)
5. [XATbackend: Web Portal](#xatbackend-web-portal)
6. [automated-Reporting: Visualization](#automated-reporting-visualization)
7. [Multi-Tenant Usage](#multi-tenant-usage)
8. [API Reference](#api-reference)
9. [Troubleshooting](#troubleshooting)
10. [FAQ](#faq)

---

## Introduction

### What is PerfAnalysis?

PerfAnalysis is an integrated ecosystem for monitoring, storing, analyzing, and visualizing system performance metrics from Linux servers.

**Key Features**:
- 📊 Real-time performance data collection from Linux `/proc` filesystem
- 🔐 Multi-tenant architecture with complete data isolation
- 🌐 Web-based portal for managing collectors and viewing data
- 📈 Automated report generation with R-based visualization
- 🔒 Secure API with authentication and role-based access control
- 🐳 Docker-based deployment for easy setup

### System Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| **perfcollector2** | Go | Collects performance metrics from Linux servers |
| **XATbackend** | Django/Python | Web portal and API for data management |
| **automated-Reporting** | R | Generates visualizations and reports |
| **PostgreSQL** | SQL Database | Stores all performance data |

---

## Quick Start

### Prerequisites

- Docker Desktop or Docker + Docker Compose
- Linux, macOS, or Windows with WSL2
- 4GB RAM minimum, 8GB recommended
- 10GB disk space

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/PerfAnalysis.git
cd PerfAnalysis

# Initialize the development environment
make init

# Verify all services are running
make health
```

You should see:
```
✅ PostgreSQL: healthy
✅ XATbackend: healthy
✅ pcd daemon: healthy
✅ R environment: ready
```

### First Steps

1. **Access the web portal**: http://localhost:8000
2. **Create an account**: Click "Sign Up" and register
3. **Set up your first collector**: Navigate to "Collectors" → "Setup"
4. **Install pcc on your server**: Follow the setup instructions
5. **Start collecting data**: The collector will automatically send data to XATbackend

---

## System Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        Linux Server                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                  │
│  │  /proc/  │───▶│   pcc    │───▶│   pcd    │                  │
│  │          │    │ (client) │    │ (daemon) │                  │
│  └──────────┘    └──────────┘    └────┬─────┘                  │
└─────────────────────────────────────────┼────────────────────────┘
                                          │ HTTP POST (JSON)
                                          ▼
                  ┌───────────────────────────────────┐
                  │        XATbackend (Django)        │
                  │  ┌──────────────────────────┐    │
                  │  │  Multi-Tenant Database   │    │
                  │  │     (PostgreSQL)         │    │
                  │  └──────────────────────────┘    │
                  └─────────────────┬─────────────────┘
                                    │ CSV Export
                                    ▼
                  ┌───────────────────────────────────┐
                  │   automated-Reporting (R)         │
                  │  ┌──────────────────────────┐    │
                  │  │   Visualizations         │    │
                  │  │   Reports                │    │
                  │  └──────────────────────────┘    │
                  └───────────────────────────────────┘
```

### Key Concepts

**Collector**: A registered server that sends performance data to XATbackend.

**Site**: A logical grouping of collectors (e.g., "DataCenter1", "AWS-East").

**Tenant**: An isolated environment for a customer or organization. Each tenant has completely separate data.

**Captured Data**: Performance metrics collected from a server at a specific time.

---

## perfcollector2: Data Collection

### Overview

perfcollector2 consists of three components:

- **pcc** (Performance Collection Client): Collects metrics from `/proc` and sends to pcd
- **pcd** (Performance Collection Daemon): HTTP API server that receives data
- **pcctl** (Performance Collection Control): CLI tool for managing collectors

### Installing on a Server

#### Option 1: Using Pre-built Binaries

```bash
# Download latest release
curl -LO https://github.com/yourusername/perfcollector2/releases/latest/download/perfcollector2-linux-amd64.tar.gz

# Extract
tar -xzf perfcollector2-linux-amd64.tar.gz

# Install binaries
sudo mv pcc pcd pcctl /usr/local/bin/

# Verify installation
pcc --version
```

#### Option 2: Building from Source

```bash
# Install Go 1.24+
# Clone repository
git clone https://github.com/yourusername/perfcollector2.git
cd perfcollector2

# Build
make build

# Install
sudo make install
```

### Configuration

Create `/etc/pcd/config.yaml`:

```yaml
# pcd daemon configuration
server:
  port: 8080
  read_timeout: 10s
  write_timeout: 10s

storage:
  data_dir: /var/lib/pcd
  api_keys_file: /var/lib/pcd/apikeys

xatbackend:
  url: http://your-xatbackend-server:8000
  upload_endpoint: /collectors/upload/
  api_key: your-api-key-here
```

### Running pcd Daemon

```bash
# Start pcd as a service
sudo pcd --config /etc/pcd/config.yaml

# Or use systemd (recommended)
sudo systemctl start pcd
sudo systemctl enable pcd
```

### Collecting Data with pcc

```bash
# Collect data once
pcc --server http://localhost:8080

# Collect every 60 seconds
pcc --server http://localhost:8080 --interval 60

# Collect with custom hostname
pcc --server http://localhost:8080 --hostname web-server-01

# Run as daemon
pcc --server http://localhost:8080 --interval 60 --daemon
```

### Collected Metrics

| Metric | Source | Description |
|--------|--------|-------------|
| **CPU** | /proc/stat | User, system, idle, I/O wait time per CPU core |
| **Memory** | /proc/meminfo | Total, used, free, cached, swap usage |
| **Network** | /proc/net/dev | RX/TX bytes, packets, errors per interface |
| **Disk** | /proc/diskstats | Reads, writes, I/O time per disk |
| **Filesystem** | statfs | Disk usage, inodes per mounted filesystem |
| **System** | /proc/cpuinfo | CPU model, cores, frequency |

### Example Data Format

```json
{
  "timestamp": 1704398400,
  "hostname": "web-server-01",
  "cpu": {
    "user": 25.5,
    "system": 10.2,
    "idle": 64.3,
    "iowait": 0.0
  },
  "memory": {
    "total_kb": 16777216,
    "used_kb": 8388608,
    "free_kb": 8388608,
    "cached_kb": 4194304
  },
  "disks": [
    {
      "device": "sda",
      "read_bytes": 1048576,
      "write_bytes": 2097152
    }
  ],
  "network": [
    {
      "interface": "eth0",
      "rx_bytes": 4194304,
      "tx_bytes": 2097152
    }
  ]
}
```

---

## XATbackend: Web Portal

### Accessing the Portal

1. Navigate to: http://your-server:8000
2. Log in with your credentials
3. (Multi-tenant setup) Use subdomain: http://tenant1.your-server:8000

### Managing Collectors

#### Creating a Collector

1. Navigate to **Collectors** → **Setup**
2. Fill in collector information:
   - **Site Name**: Logical grouping (e.g., "Production-East")
   - **Machine Name**: Server hostname (e.g., "web-01")
   - **Platform**: Operating system (e.g., "Linux Server")
3. Click **Create Collector**
4. Note the **Collector ID** for configuration

#### Viewing Collectors

Navigate to **Collectors** → **Manage**

You'll see a list of all your collectors with:
- Machine name
- Site name
- Platform
- Last upload time
- Number of uploaded files
- Status (active/inactive)

#### Uploading Data Manually

1. Go to **Collectors** → **Manage**
2. Click on a collector
3. Click **Upload File**
4. Select CSV or JSON file
5. Add description (optional)
6. Click **Upload**

### Managing Uploaded Data

#### Viewing Uploaded Files

1. Navigate to **Collectors** → **Manage**
2. Click on a collector
3. View list of uploaded files with:
   - Filename
   - Upload date
   - File size
   - Description

#### Downloading Data

Click the **Download** icon next to any file to download the raw data.

#### Deleting Data

Click the **Delete** icon next to a file (requires permissions).

### User Management

#### User Roles

| Role | Permissions |
|------|-------------|
| **Admin** | Full access - manage users, collectors, data |
| **Analyst** | View and analyze data, upload files |
| **Viewer** | Read-only access to data and reports |

#### Creating Users (Admin only)

1. Navigate to **Admin** → **Users**
2. Click **Add User**
3. Fill in details:
   - Username
   - Email
   - Password
   - Role
4. Click **Create**

#### Changing Password

1. Navigate to **Account** → **Settings**
2. Click **Change Password**
3. Enter current and new password
4. Click **Update**

---

## automated-Reporting: Visualization

### Overview

The automated-Reporting component generates visualizations and reports from collected performance data.

### Generating Reports

#### Using R Scripts

```r
# Load required libraries
library(ggplot2)
library(data.table)

# Load performance data
data <- fread("/path/to/performance_data.csv")

# Convert timestamp
data[, timestamp := as.POSIXct(timestamp, origin="1970-01-01")]

# Generate CPU usage plot
ggplot(data, aes(x = timestamp, y = cpu_user)) +
  geom_line(color = "blue") +
  labs(
    title = "CPU Usage Over Time",
    x = "Time",
    y = "CPU Usage (%)"
  ) +
  theme_minimal()

# Save plot
ggsave("cpu_usage_report.png", width = 10, height = 6)
```

### Available Report Templates

1. **CPU Usage Report**: Line chart of CPU utilization over time
2. **Memory Usage Report**: Memory consumption trends
3. **Network Traffic Report**: Network I/O visualization
4. **Disk I/O Report**: Disk read/write patterns
5. **System Summary**: Multi-metric dashboard

### Exporting Data for R

#### From XATbackend

1. Navigate to **Collectors** → **Manage**
2. Select collector
3. Click **Export to CSV**
4. Save CSV file
5. Use in R scripts

#### Programmatic Export

```python
# Export via Django management command
docker-compose exec xatbackend python manage.py export_collector_data \
  --collector-id 123 \
  --output /tmp/data.csv \
  --start-date 2024-01-01 \
  --end-date 2024-01-31
```

---

## Multi-Tenant Usage

### For Administrators

#### Creating a Tenant

```python
# Using Django shell
docker-compose exec xatbackend python manage.py shell

from partners.models import Client, Domain

# Create tenant
tenant = Client.objects.create(
    schema_name='acme_corp',
    name='Acme Corporation',
    description='Production tenant for Acme Corp',
    on_trial=False
)

# Create domain
domain = Domain.objects.create(
    tenant=tenant,
    domain='acmecorp.perfanalysis.com',
    is_primary=True
)
```

#### Managing Tenants

```bash
# List all tenants
docker-compose exec xatbackend python manage.py list_tenants

# Migrate tenant schema
docker-compose exec xatbackend python manage.py migrate_schemas

# Create superuser for tenant
docker-compose exec xatbackend python manage.py create_tenant_superuser \
  --schema=acme_corp
```

### For Tenants

#### Accessing Your Tenant

Navigate to your assigned subdomain:
```
http://your-tenant.perfanalysis.com
```

#### Data Isolation

All data is completely isolated between tenants:
- ✅ Separate PostgreSQL schemas
- ✅ Separate user accounts
- ✅ Separate collectors and data
- ✅ No cross-tenant visibility

---

## API Reference

### Authentication

All API requests require authentication via API key.

```bash
# Get API key from web portal
# Settings → API Keys → Generate New Key

# Use in requests
curl -H "Authorization: ApiKey username:api-key-here" \
  http://localhost:8000/api/v1/collectors/
```

### Endpoints

#### List Collectors

```bash
GET /api/v1/collectors/

curl -H "Authorization: ApiKey user:key" \
  http://localhost:8000/api/v1/collectors/

Response:
{
  "count": 10,
  "results": [
    {
      "id": 1,
      "machinename": "web-01",
      "sitename": "Production",
      "platform": "Linux Server",
      "last_upload": "2024-01-04T10:30:00Z"
    }
  ]
}
```

#### Get Collector Details

```bash
GET /api/v1/collectors/{id}/

curl -H "Authorization: ApiKey user:key" \
  http://localhost:8000/api/v1/collectors/1/

Response:
{
  "id": 1,
  "machinename": "web-01",
  "sitename": "Production",
  "platform": "Linux Server",
  "created_at": "2024-01-01T00:00:00Z",
  "files_count": 245
}
```

#### Upload Data

```bash
POST /api/v1/collectors/{id}/upload/

curl -X POST \
  -H "Authorization: ApiKey user:key" \
  -F "file=@performance_data.csv" \
  -F "description=Hourly metrics" \
  http://localhost:8000/api/v1/collectors/1/upload/

Response:
{
  "id": 567,
  "filename": "performance_data.csv",
  "upload_date": "2024-01-04T10:30:00Z",
  "file_size": 245678
}
```

#### List Uploaded Files

```bash
GET /api/v1/collectors/{id}/files/

curl -H "Authorization: ApiKey user:key" \
  http://localhost:8000/api/v1/collectors/1/files/

Response:
{
  "count": 245,
  "results": [
    {
      "id": 567,
      "filename": "performance_data.csv",
      "upload_date": "2024-01-04T10:30:00Z",
      "file_size": 245678,
      "description": "Hourly metrics"
    }
  ]
}
```

### Error Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request - Invalid parameters |
| 401 | Unauthorized - Invalid or missing API key |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource doesn't exist |
| 500 | Server Error - Contact administrator |

---

## Troubleshooting

### Common Issues

#### 1. Cannot Connect to XATbackend

**Symptoms**: `Connection refused` or timeout errors

**Solutions**:
```bash
# Check if services are running
docker-compose ps

# Check logs
docker-compose logs xatbackend

# Restart services
docker-compose restart xatbackend
```

#### 2. Data Not Appearing in Portal

**Symptoms**: Uploaded files don't show up

**Solutions**:
```bash
# Check collector ownership
docker-compose exec xatbackend python manage.py shell
>>> from collectors.models import Collector
>>> c = Collector.objects.get(machinename='your-machine')
>>> c.owner  # Should match your user

# Check file permissions
docker-compose exec xatbackend ls -la /app/media/uploads/
```

#### 3. pcd Daemon Won't Start

**Symptoms**: `pcd` exits immediately or connection refused

**Solutions**:
```bash
# Check configuration
cat /etc/pcd/config.yaml

# Check logs
journalctl -u pcd -f

# Test manually
pcd --config /etc/pcd/config.yaml --verbose
```

#### 4. Database Migrations Failing

**Symptoms**: `Table doesn't exist` errors

**Solutions**:
```bash
# Run migrations
docker-compose exec xatbackend python manage.py migrate

# Check migration status
docker-compose exec xatbackend python manage.py showmigrations

# Specific app migration
docker-compose exec xatbackend python manage.py migrate collectors
```

#### 5. Performance Issues

**Symptoms**: Slow response times, high CPU usage

**Solutions**:
```bash
# Check resource usage
docker stats

# Check database queries
docker-compose exec postgres psql -U perfadmin -d perfanalysis \
  -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"

# Add indexes (see PERFORMANCE_OPTIMIZATION.md)

# Review optimization guide
cat PERFORMANCE_OPTIMIZATION.md
```

### Getting Help

1. **Check logs**: `docker-compose logs [service]`
2. **Review documentation**: All .md files in repository
3. **Search issues**: GitHub Issues page
4. **Contact support**: support@perfanalysis.com

---

## FAQ

### General Questions

**Q: Is PerfAnalysis suitable for production use?**
A: Yes, with proper configuration and security hardening (see SECURITY.md).

**Q: What platforms are supported?**
A: Linux servers for data collection. Web portal works on any modern browser.

**Q: How much data can the system handle?**
A: Tested with 100+ collectors sending data every 60 seconds. PostgreSQL partitioning supports millions of records.

**Q: Is there a cloud-hosted version?**
A: Self-hosted only currently. Cloud version planned for future.

### Technical Questions

**Q: Can I collect custom metrics?**
A: Yes, modify pcc to collect additional /proc files or custom data sources.

**Q: How is data encrypted?**
A: TLS 1.2+ for data in transit, PostgreSQL encryption at rest (configure separately).

**Q: Can I integrate with existing monitoring tools?**
A: Yes, via API. Export data to Grafana, Prometheus, etc.

**Q: What's the data retention policy?**
A: Configurable per tenant. Default is unlimited with manual archiving.

### Billing & Licensing

**Q: Is PerfAnalysis free?**
A: Open source under MIT License. Free for commercial and personal use.

**Q: Can I modify the code?**
A: Yes, MIT License allows modification and redistribution.

**Q: Is support available?**
A: Community support via GitHub Issues. Commercial support available on request.

---

## Next Steps

1. **Set up your first collector**: Follow the perfcollector2 installation guide
2. **Explore the API**: Try the API endpoints with curl or Postman
3. **Generate reports**: Use R scripts to visualize your data
4. **Optimize performance**: Review PERFORMANCE_OPTIMIZATION.md
5. **Secure your deployment**: Read SECURITY.md

For deployment to production, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

For API integration examples, see [API_EXAMPLES.md](API_EXAMPLES.md).

For contributing, see [CONTRIBUTING.md](CONTRIBUTING.md).

---

**Need help?** Contact support@perfanalysis.com or open an issue on GitHub.
