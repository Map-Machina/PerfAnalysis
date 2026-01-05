# PerfAnalysis System Architecture

**Version**: 1.0
**Date**: 2026-01-05
**Status**: Development
**Agent Assignment**: Solutions Architect, Integration Architect, Security Architect, Data Architect

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Component Architecture](#component-architecture)
4. [Data Flow](#data-flow)
5. [API Contracts](#api-contracts)
6. [Database Schema](#database-schema)
7. [Security Architecture](#security-architecture)
8. [Deployment Architecture](#deployment-architecture)
9. [Technology Stack](#technology-stack)

---

## 1. System Overview

PerfAnalysis is an integrated performance monitoring ecosystem that collects, stores, analyzes, and visualizes system performance metrics from Linux servers. The system consists of three integrated components working together in a data pipeline.

### 1.1 System Purpose

- **Collect** system performance metrics from Linux /proc filesystem
- **Store** multi-tenant performance data with schema isolation
- **Analyze** and visualize performance trends over time
- **Alert** on performance anomalies and thresholds

### 1.2 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                      PERFANALYSIS ECOSYSTEM                           │
└──────────────────────────────────────────────────────────────────────┘

┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ perfcollector2  │────────▶│   XATbackend    │────────▶│   automated-    │
│   (Go-based)    │  HTTP   │ (Django Portal) │  Export │   Reporting     │
│                 │  POST   │                 │  CSV/API│   (R-based)     │
│ DATA COLLECTION │         │ USER PORTAL     │         │ VISUALIZATION   │
└─────────────────┘         └─────────────────┘         └─────────────────┘
       │                            │                            │
       │                            │                            │
   Linux /proc             PostgreSQL 12.2              Oracle 26ai
   Filesystem              (Multi-tenant)               (Future)
```

### 1.3 Key Features

- **Multi-tenant architecture** with PostgreSQL schema isolation
- **Real-time data collection** from Linux /proc filesystem
- **RESTful API** for data upload and export
- **Automated reporting** with R Markdown
- **Role-based access control** with Django authentication
- **Scalable architecture** for cloud deployment (Azure)

---

## 2. Architecture Diagram

### 2.1 Component Integration

```
┌────────────────────────────────────────────────────────────────────────────┐
│                           PERFANALYSIS SYSTEM                               │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │ COLLECTION LAYER                                                     │  │
│  │                                                                       │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐   │  │
│  │  │    pcc     │  │    pcc     │  │    pcc     │  │    pcc     │   │  │
│  │  │  (Agent)   │  │  (Agent)   │  │  (Agent)   │  │  (Agent)   │   │  │
│  │  │ Server 1   │  │ Server 2   │  │ Server 3   │  │ Server N   │   │  │
│  │  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘   │  │
│  │        │               │               │               │           │  │
│  └────────┼───────────────┼───────────────┼───────────────┼───────────┘  │
│           │               │               │               │               │
│           └───────────────┴───────────────┴───────────────┘               │
│                                   │                                        │
│                         HTTP POST (CSV + Metadata)                        │
│                              Bearer Token Auth                            │
│                                   │                                        │
│  ┌────────────────────────────────▼───────────────────────────────────┐  │
│  │ STORAGE & API LAYER                                                 │  │
│  │                                                                      │  │
│  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │              XATbackend (Django 3.2.3)                        │  │  │
│  │  │                                                                │  │  │
│  │  │  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐        │  │  │
│  │  │  │   Upload    │  │ Multi-Tenant │  │    User      │        │  │  │
│  │  │  │     API     │  │  Middleware  │  │   Portal     │        │  │  │
│  │  │  │ /api/v1/... │  │(django-tenants)│ (Web UI)    │        │  │  │
│  │  │  └─────────────┘  └──────────────┘  └──────────────┘        │  │  │
│  │  │                                                                │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────┐ │  │  │
│  │  │  │           PostgreSQL 12.2 (Multi-tenant)                 │ │  │  │
│  │  │  │                                                           │ │  │  │
│  │  │  │  public │ tenant1 │ tenant2 │ tenant3 │ ... │ tenantN   │ │  │  │
│  │  │  │  schema │ schema  │ schema  │ schema  │     │ schema    │ │  │  │
│  │  │  └─────────────────────────────────────────────────────────┘ │  │  │
│  │  └──────────────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────┬───────────────────────────────────────┘  │
│                                  │                                          │
│                       CSV Export / REST API                                │
│                                  │                                          │
│  ┌──────────────────────────────▼───────────────────────────────────┐    │
│  │ VISUALIZATION LAYER                                               │    │
│  │                                                                    │    │
│  │  ┌──────────────────────────────────────────────────────────┐    │    │
│  │  │       automated-Reporting (R 4.5.2)                       │    │    │
│  │  │                                                            │    │    │
│  │  │  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐    │    │    │
│  │  │  │ Data Import │  │  R Markdown  │  │   ggplot2    │    │    │    │
│  │  │  │  (CSV/API)  │  │   Reports    │  │ Visualization│    │    │    │
│  │  │  └─────────────┘  └──────────────┘  └──────────────┘    │    │    │
│  │  │                                                            │    │    │
│  │  │  Output: HTML/PDF Performance Reports                     │    │    │
│  │  └──────────────────────────────────────────────────────────┘    │    │
│  └───────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Deployment View (Development)

```
┌─────────────────────────────────────────────────────────────────┐
│                    Docker Compose Network                        │
│                   (perfanalysis-network)                         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ postgres:5432│  │xatbackend:8000│ │   pcd:8080   │         │
│  │              │  │              │  │              │         │
│  │ PostgreSQL   │◀─│   Django     │◀─│ perfcollector│         │
│  │   12.2       │  │    3.2.3     │  │   daemon     │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│         │                  │                                    │
│         ▼                  ▼                                    │
│  ┌──────────────┐  ┌──────────────┐                           │
│  │postgres_data │  │ XATbackend/  │                           │
│  │   Volume     │  │   (mount)    │                           │
│  └──────────────┘  └──────────────┘                           │
│                                                                  │
│  ┌──────────────────────────────────────┐                      │
│  │        r-dev (Interactive)           │                      │
│  │        R 4.5.2 + renv                │                      │
│  └──────────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Component Architecture

### 3.1 perfcollector2 (Go Data Collector)

**Purpose**: Collect system performance metrics from Linux /proc filesystem and upload to XATbackend

**Components**:

```
perfcollector2/
├── cmd/
│   ├── pcc/          # Performance Collection Client (collector agent)
│   ├── pcd/          # Performance Collection Daemon (API server)
│   ├── pcctl/        # Performance Collection Control (CLI tool)
│   └── pcprocess/    # CSV data processor
├── measurement/      # Measurement data structures
├── collector/        # /proc filesystem parsers
└── api/             # HTTP API handlers
```

**Key Features**:
- **pcc** - Runs on target servers, collects /proc metrics, uploads via HTTP
- **pcd** - Central daemon accepting uploads, storing locally, forwarding to XATbackend
- **pcctl** - Administrative CLI for managing collectors
- **pcprocess** - Processes and transforms collected data

**Data Sources** (Linux /proc):
- `/proc/stat` - CPU statistics
- `/proc/meminfo` - Memory usage
- `/proc/diskstats` - Disk I/O
- `/proc/net/dev` - Network statistics
- `/proc/loadavg` - System load average

**Output Format**: CSV files with timestamp, machine_id, and metric columns

### 3.2 XATbackend (Django User Portal)

**Purpose**: Multi-tenant web portal for managing performance data, users, and access control

**Architecture**:

```
XATbackend/
├── core/              # Django settings
├── partners/          # Multi-tenant models (Partner, Domain)
├── collectors/        # Machine/collector registration
├── analysis/          # Performance data storage
├── authentication/    # User authentication
└── api/              # REST API endpoints
```

**Multi-Tenancy Model**:
- **Public Schema**: Shared tenant metadata (partners, domains)
- **Tenant Schemas**: Isolated data per organization (collectors, analysis, users)
- **URL Routing**: Subdomain-based tenant resolution (tenant1.perfanalysis.com)

**Key Models**:

```python
# Public Schema
Partner (TenantMixin)
  - schema_name
  - name
  - active
  - paid_until

Domain (DomainMixin)
  - domain
  - tenant (FK → Partner)
  - is_primary

# Tenant Schema (per Partner)
Collector
  - machine_id
  - hostname
  - api_key

AnalysisData
  - timestamp
  - collector (FK)
  - metrics (JSON/columns)
```

**API Endpoints**:
- `POST /api/v1/performance/upload` - Upload CSV data (authenticated)
- `GET /api/v1/performance/export` - Export data for reporting
- `GET /api/v1/collectors` - List registered collectors
- `POST /api/v1/collectors/register` - Register new collector

### 3.3 automated-Reporting (R Visualization)

**Purpose**: Generate HTML/PDF performance reports with charts and analysis

**Architecture**:

```
automated-Reporting/
├── reporting.Rmd       # R Markdown report template
├── renv_init.R        # Package initialization
├── renv.lock          # Package versions (generated)
└── testData/          # Sample data for development
```

**Key Capabilities**:
- **Data Import**: Read CSV exports from XATbackend
- **Visualization**: ggplot2 charts (time series, distributions, correlations)
- **Analysis**: Statistical summaries, trend detection
- **Output**: HTML reports with interactive charts, PDF for distribution

**Report Sections**:
1. Executive Summary - Key metrics overview
2. CPU Analysis - Usage trends, core distribution
3. Memory Analysis - Usage patterns, swap activity
4. Disk I/O - Throughput, latency, queue depth
5. Network - Bandwidth, packet rates, errors
6. Recommendations - Performance optimization suggestions

---

## 4. Data Flow

### 4.1 End-to-End Data Flow

```
┌──────────────────────────────────────────────────────────────────────┐
│ STAGE 1: COLLECTION                                                  │
└──────────────────────────────────────────────────────────────────────┘

Linux Server /proc      →    pcc Agent       →    Local CSV
(Real-time metrics)         (Go collector)        (/tmp/perf_*.csv)

Frequency: Every 60s (configurable)
Data: timestamp, machine_id, cpu%, mem%, disk_io, net_io


┌──────────────────────────────────────────────────────────────────────┐
│ STAGE 2: UPLOAD                                                      │
└──────────────────────────────────────────────────────────────────────┘

Local CSV    →    HTTP POST    →    XATbackend API    →    PostgreSQL
                  (Multipart)        (/api/v1/upload)        (Tenant schema)

Authentication: Bearer token (per-machine API key)
Format: CSV file + metadata (machine_id, tenant_id)
Frequency: Batch upload every 5 minutes (configurable)


┌──────────────────────────────────────────────────────────────────────┐
│ STAGE 3: STORAGE                                                     │
└──────────────────────────────────────────────────────────────────────┘

PostgreSQL    →    Tenant Schema    →    analysis_data table
                   (Isolated)             (Indexed by timestamp, collector)

Retention: 90 days (configurable)
Partitioning: Monthly partitions for large datasets


┌──────────────────────────────────────────────────────────────────────┐
│ STAGE 4: EXPORT                                                      │
└──────────────────────────────────────────────────────────────────────┘

PostgreSQL    →    Django ORM    →    CSV Export    →    R Import
                   (Query)            (/exports/*)        (read.csv)

Filters: Date range, machine_id, metric types
Format: Standardized CSV columns


┌──────────────────────────────────────────────────────────────────────┐
│ STAGE 5: VISUALIZATION                                               │
└──────────────────────────────────────────────────────────────────────┘

CSV Data    →    R Processing    →    ggplot2 Charts    →    HTML/PDF
                 (data.table)         (time series)           Report

Output: Performance analysis report with recommendations
```

### 4.2 Data Flow Sequences

#### Sequence 1: Data Collection & Upload

```
pcc Agent              pcd Daemon            XATbackend          PostgreSQL
    │                      │                      │                   │
    ├─ Read /proc ────────>│                      │                   │
    ├─ Parse metrics       │                      │                   │
    ├─ Write CSV           │                      │                   │
    │                      │                      │                   │
    ├─ POST /v1/upload ───>│                      │                   │
    │  (CSV file)          │                      │                   │
    │                      ├─ Validate API key    │                   │
    │                      ├─ Store locally       │                   │
    │                      │                      │                   │
    │                      ├─ POST /api/v1/upload>│                   │
    │                      │  (multipart/form)    │                   │
    │                      │                      ├─ Authenticate     │
    │                      │                      ├─ Resolve tenant   │
    │                      │                      ├─ Parse CSV        │
    │                      │                      ├─ INSERT ─────────>│
    │                      │                      │                   │
    │<── 200 OK ───────────┤<──── 201 Created ───┤<─── Commit ───────┤
    │                      │                      │                   │
```

#### Sequence 2: Report Generation

```
User                XATbackend          PostgreSQL         R Script
 │                      │                   │                 │
 ├─ Request report ────>│                   │                 │
 │  (date range, ID)    │                   │                 │
 │                      ├─ SELECT ─────────>│                 │
 │                      │                   │                 │
 │                      │<─── Rows ─────────┤                 │
 │                      │                   │                 │
 │                      ├─ Export CSV ──────────────────────>│
 │                      │                   │                 │
 │                      │                   │  ├─ Load data   │
 │                      │                   │  ├─ Process     │
 │                      │                   │  ├─ Visualize   │
 │                      │                   │  ├─ Render HTML │
 │                      │                   │                 │
 │<─────────────────────────── HTML Report ───────────────────┤
 │                      │                   │                 │
```

---

## 5. API Contracts

### 5.1 perfcollector2 → XATbackend Upload API

**Endpoint**: `POST /api/v1/performance/upload`

**Authentication**: Bearer token (per-machine API key)

**Request**:
```http
POST /api/v1/performance/upload HTTP/1.1
Host: perfanalysis.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="perf_server1_20260105.csv"
Content-Type: text/csv

timestamp,machine_id,cpu_user,cpu_system,mem_used_mb,disk_read_mb,disk_write_mb
2026-01-05T10:00:00Z,server1,45.2,12.3,8192,150,75
2026-01-05T10:01:00Z,server1,47.1,11.8,8205,155,80
------WebKitFormBoundary
Content-Disposition: form-data; name="machine_id"

server1
------WebKitFormBoundary--
```

**Response** (Success):
```json
{
  "status": "success",
  "message": "Performance data uploaded successfully",
  "records_processed": 120,
  "timestamp": "2026-01-05T10:05:23Z"
}
```

**Response** (Error):
```json
{
  "status": "error",
  "error": "Authentication failed: Invalid API key",
  "code": "AUTH_001"
}
```

**CSV Format Specification**:

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| timestamp | ISO8601 | Yes | Measurement timestamp (UTC) |
| machine_id | String | Yes | Unique server identifier |
| cpu_user | Float | Yes | CPU user % (0-100 per core) |
| cpu_system | Float | Yes | CPU system % (0-100 per core) |
| cpu_idle | Float | Yes | CPU idle % (0-100 per core) |
| mem_total_mb | Integer | Yes | Total memory (MB) |
| mem_used_mb | Integer | Yes | Used memory (MB) |
| mem_free_mb | Integer | Yes | Free memory (MB) |
| mem_cached_mb | Integer | Yes | Cached memory (MB) |
| swap_total_mb | Integer | Yes | Total swap (MB) |
| swap_used_mb | Integer | Yes | Used swap (MB) |
| disk_read_mb | Float | Yes | Disk read throughput (MB/s) |
| disk_write_mb | Float | Yes | Disk write throughput (MB/s) |
| net_rx_mb | Float | Yes | Network receive (MB/s) |
| net_tx_mb | Float | Yes | Network transmit (MB/s) |

### 5.2 XATbackend → automated-Reporting Export API

**Endpoint**: `GET /api/v1/performance/export`

**Authentication**: Session-based (Django auth) or API token

**Request**:
```http
GET /api/v1/performance/export?start_date=2026-01-01&end_date=2026-01-05&machine_id=server1 HTTP/1.1
Host: tenant1.perfanalysis.example.com
Cookie: sessionid=abc123...
```

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| start_date | Date (YYYY-MM-DD) | Yes | Start of date range |
| end_date | Date (YYYY-MM-DD) | Yes | End of date range |
| machine_id | String | No | Filter by machine (optional) |
| format | String | No | Output format (csv, json) - default: csv |

**Response** (CSV):
```csv
timestamp,machine_id,cpu_user,cpu_system,mem_used_mb,disk_read_mb,disk_write_mb,net_rx_mb,net_tx_mb
2026-01-05T10:00:00Z,server1,45.2,12.3,8192,150,75,25,30
2026-01-05T10:01:00Z,server1,47.1,11.8,8205,155,80,27,32
...
```

---

## 6. Database Schema

### 6.1 Multi-Tenant Architecture

**Schema Organization**:
```
PostgreSQL Database: perfanalysis
├── public schema (shared)
│   ├── partners_partner
│   ├── partners_domain
│   ├── django_tenants_*
│   └── auth_*
├── tenant1 schema (isolated)
│   ├── collectors_collector
│   ├── analysis_data
│   └── auth_user
├── tenant2 schema (isolated)
│   └── ...
└── tenantN schema (isolated)
```

### 6.2 Public Schema (Shared)

**partners_partner** (Tenant metadata):
```sql
CREATE TABLE partners_partner (
    id SERIAL PRIMARY KEY,
    schema_name VARCHAR(63) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    info_url TEXT,
    created_on DATE NOT NULL DEFAULT CURRENT_DATE,
    paid_until DATE
);

CREATE INDEX idx_partner_active_created ON partners_partner(active, created_on);
CREATE INDEX idx_partner_paid_until ON partners_partner(paid_until);
```

**partners_domain** (URL routing):
```sql
CREATE TABLE partners_domain (
    id SERIAL PRIMARY KEY,
    domain VARCHAR(253) UNIQUE NOT NULL,
    tenant_id INTEGER REFERENCES partners_partner(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_domain_tenant ON partners_domain(tenant_id);
```

### 6.3 Tenant Schema (Per-organization)

**collectors_collector** (Machine registration):
```sql
CREATE TABLE collectors_collector (
    id SERIAL PRIMARY KEY,
    machine_id VARCHAR(100) UNIQUE NOT NULL,
    hostname VARCHAR(255),
    ip_address INET,
    api_key_hash VARCHAR(255) NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP
);

CREATE INDEX idx_collector_machine_id ON collectors_collector(machine_id);
CREATE INDEX idx_collector_active ON collectors_collector(active);
```

**analysis_data** (Performance metrics):
```sql
CREATE TABLE analysis_data (
    id BIGSERIAL PRIMARY KEY,
    collector_id INTEGER REFERENCES collectors_collector(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,

    -- CPU metrics
    cpu_user FLOAT,
    cpu_system FLOAT,
    cpu_idle FLOAT,
    cpu_iowait FLOAT,

    -- Memory metrics
    mem_total_mb INTEGER,
    mem_used_mb INTEGER,
    mem_free_mb INTEGER,
    mem_cached_mb INTEGER,
    mem_buffers_mb INTEGER,
    swap_total_mb INTEGER,
    swap_used_mb INTEGER,

    -- Disk I/O metrics
    disk_read_mb FLOAT,
    disk_write_mb FLOAT,
    disk_io_util FLOAT,

    -- Network metrics
    net_rx_mb FLOAT,
    net_tx_mb FLOAT,
    net_rx_errors INTEGER,
    net_tx_errors INTEGER,

    -- Load average
    load_1min FLOAT,
    load_5min FLOAT,
    load_15min FLOAT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Critical indexes for query performance
CREATE INDEX idx_analysis_timestamp ON analysis_data(timestamp DESC);
CREATE INDEX idx_analysis_collector_timestamp ON analysis_data(collector_id, timestamp DESC);
CREATE INDEX idx_analysis_created ON analysis_data(created_at);

-- Partitioning for large datasets (monthly partitions)
-- Implemented via pg_partman or manual partition creation
```

### 6.4 Data Retention & Partitioning

**Retention Policy**:
- Default: 90 days
- Configurable per tenant
- Automated cleanup via Django management command

**Partitioning Strategy** (for large datasets):
```sql
-- Example monthly partition
CREATE TABLE analysis_data_2026_01 PARTITION OF analysis_data
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE analysis_data_2026_02 PARTITION OF analysis_data
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
```

---

## 7. Security Architecture

### 7.1 Authentication & Authorization

**Authentication Layers**:

1. **Machine-to-API Authentication** (perfcollector2 → XATbackend):
   - API key per machine (collector)
   - Hashed storage (bcrypt/Django hasher)
   - Bearer token in Authorization header
   - Key rotation supported via API

2. **User Authentication** (Web portal):
   - Django session-based authentication
   - Password hashing (PBKDF2 with SHA256)
   - Optional: OAuth2/OIDC integration
   - MFA support (django-otp)

3. **Tenant Isolation**:
   - URL-based tenant resolution (subdomain)
   - PostgreSQL schema-level isolation
   - Row-level security (RLS) for sensitive data
   - No cross-tenant data access

**Authorization Model**:

```
Tenant (Organization)
├── Admin (full tenant access)
│   ├── Manage users
│   ├── Manage collectors
│   ├── View all data
│   └── Generate reports
├── Analyst (read-only)
│   ├── View data
│   └── Generate reports
└── Viewer (limited read)
    └── View dashboards
```

### 7.2 Data Security

**Encryption**:
- **In Transit**: TLS 1.2+ (HTTPS) for all API communication
- **At Rest**: PostgreSQL encryption (pgcrypto) for sensitive columns
- **Secrets**: Azure Key Vault for production credentials

**API Key Management**:
```python
# API key generation
import secrets
api_key = secrets.token_urlsafe(32)  # 256-bit entropy

# Storage (hashed)
from django.contrib.auth.hashers import make_password
api_key_hash = make_password(api_key)

# Validation
from django.contrib.auth.hashers import check_password
is_valid = check_password(provided_key, stored_hash)
```

**Security Headers** (Django middleware):
```python
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
X_FRAME_OPTIONS = 'DENY'
SECURE_CONTENT_TYPE_NOSNIFF = True
```

### 7.3 Network Security

**Firewall Rules** (Production):
```
Ingress:
  - Port 443 (HTTPS): Allow from Internet (XATbackend web)
  - Port 8080 (HTTP): Allow from collector IPs (pcd API)
  - Port 5432 (PostgreSQL): Deny from Internet (internal only)

Egress:
  - Port 443: Allow (external APIs, package repos)
  - All other: Deny by default
```

**Rate Limiting**:
- API endpoints: 100 requests/minute per IP
- Upload endpoint: 10 uploads/minute per machine
- Django middleware: django-ratelimit

### 7.4 Audit Logging

**Audit Events**:
- User login/logout
- API key generation/rotation
- Data uploads (timestamp, machine_id, record count)
- Export operations (user, date range, machine)
- Admin actions (user creation, permission changes)

**Log Format** (JSON):
```json
{
  "timestamp": "2026-01-05T10:15:23Z",
  "event": "data_upload",
  "user": "collector_server1",
  "tenant": "tenant1",
  "machine_id": "server1",
  "records": 120,
  "ip": "192.168.1.100",
  "status": "success"
}
```

---

## 8. Deployment Architecture

### 8.1 Development Environment (Current)

**Docker Compose** - See [docker-compose.yml](docker-compose.yml)

```
Services:
  - postgres:5432 (PostgreSQL 12.2)
  - xatbackend:8000 (Django development server)
  - pcd:8080 (Go daemon)
  - r-dev (R interactive environment)

Volumes:
  - postgres_data (persistent database)
  - pcd_data (collector data)

Networks:
  - perfanalysis-network (bridge)
```

**Access**:
- XATbackend: http://localhost:8000
- pcd API: http://localhost:8080
- PostgreSQL: localhost:5432 (user: perfadmin)

### 8.2 Production Architecture (Azure)

**Planned Deployment**:

```
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Cloud (East US)                       │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Azure Front Door (CDN + WAF)                               │ │
│  │ - SSL termination                                          │ │
│  │ - DDoS protection                                          │ │
│  └────────────────┬───────────────────────────────────────────┘ │
│                   │                                              │
│  ┌────────────────▼───────────────────────────────────────────┐ │
│  │ App Service Plan (Linux, Premium P2v3)                     │ │
│  │                                                             │ │
│  │  ┌─────────────────┐         ┌─────────────────┐          │ │
│  │  │  XATbackend     │         │   pcd Daemon    │          │ │
│  │  │  (Django)       │         │   (Go)          │          │ │
│  │  │  Instances: 2-4 │         │   Instances: 1  │          │ │
│  │  └────────┬────────┘         └────────┬────────┘          │ │
│  └───────────┼──────────────────────────┼────────────────────┘ │
│              │                           │                      │
│  ┌───────────▼───────────────────────────▼────────────────────┐ │
│  │ Azure Database for PostgreSQL (Flexible Server)            │ │
│  │ - Version: 12                                              │ │
│  │ - SKU: General Purpose, 4 vCores, 32GB RAM                │ │
│  │ - Storage: 512GB, auto-grow enabled                       │ │
│  │ - Backup: 7-day retention, geo-redundant                  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Azure Key Vault                                            │ │
│  │ - Database credentials                                     │ │
│  │ - Django SECRET_KEY                                        │ │
│  │ - API keys (optional)                                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Azure Monitor + Log Analytics                              │ │
│  │ - Application insights                                     │ │
│  │ - Performance metrics                                      │ │
│  │ - Custom dashboards                                        │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Scaling Strategy**:
- **Horizontal**: Auto-scale App Service (2-10 instances based on CPU)
- **Vertical**: Database can scale up to 64 vCores if needed
- **Read Replicas**: PostgreSQL read replicas for reporting queries

**High Availability**:
- App Service: Zone-redundant deployment
- Database: 99.99% SLA with automatic failover
- Backup: Automated daily backups, 7-day retention

### 8.3 Monitoring & Observability

**Application Monitoring**:
- Azure Application Insights integration
- Custom metrics: upload rate, processing time, error rate
- Distributed tracing for multi-component requests

**Database Monitoring**:
- Query performance insights
- Slow query log (>1s queries)
- Connection pool monitoring

**Alerts**:
- Error rate > 1%
- Response time > 2s (p95)
- Database connection pool > 80%
- Disk usage > 85%

---

## 9. Technology Stack

### 9.1 Component Technologies

| Component | Language | Framework | Database | Version |
|-----------|----------|-----------|----------|---------|
| **perfcollector2** | Go 1.24+ | net/http, encoding/json | N/A | 1.0.0-dev |
| **XATbackend** | Python 3.10 | Django 3.2.3, django-tenants 3.3.1 | PostgreSQL 12.2 | 1.0.0 |
| **automated-Reporting** | R 4.5.2 | R Markdown, ggplot2, data.table | Oracle 26ai (future) | 1.0.0 |

### 9.2 Key Dependencies

**perfcollector2** (Go):
```
go 1.24.2
```

**XATbackend** (Python):
```
Django==3.2.3
django-tenants==3.3.1
djangorestframework==3.12.4
psycopg2-binary==2.9.1
django-environ==0.4.5
python-decouple==3.4
```

**automated-Reporting** (R):
```
ggplot2
dplyr
lubridate
data.table
knitr
rmarkdown
```

### 9.3 Development Tools

**Local Development**:
- Docker 20.10+
- Docker Compose 2.0+
- Make (build automation)

**CI/CD** (Planned):
- GitHub Actions
- golangci-lint (Go)
- pylint, black (Python)
- lintr (R)

**Testing**:
- Go: `go test`
- Django: `pytest` + `django.test`
- R: `testthat`

---

## 10. Performance Considerations

### 10.1 Expected Load

**Collection Rate**:
- 100 servers × 60-second intervals = ~1.67 measurements/second
- Daily data: 100 servers × 1440 minutes = 144,000 records/day
- Monthly: ~4.3 million records

**Storage Requirements**:
- Per record: ~200 bytes (compressed)
- Monthly: 4.3M × 200B = ~860 MB/month
- Annual (with overhead): ~12 GB/year per 100 servers

**Query Performance Targets**:
- Data upload: <500ms (p95)
- Export query: <2s for 7-day range (p95)
- Dashboard load: <1s (p95)

### 10.2 Optimization Strategies

**Database**:
- Partitioning by month for `analysis_data` table
- Index on (collector_id, timestamp DESC)
- PostgreSQL connection pooling (pgbouncer)

**API**:
- Batch uploads (multiple records per request)
- Async processing for large CSV files (Celery)
- Redis caching for frequently accessed data

**Reporting**:
- Pre-aggregated summary tables
- Materialized views for common queries
- Incremental report updates

---

## Appendices

### A. Glossary

- **Tenant**: An organization/partner using the system with isolated data
- **Collector**: A machine running pcc agent that sends performance data
- **Schema**: PostgreSQL schema providing data isolation per tenant
- **Measurement**: A single data point with timestamp and metrics

### B. References

- [Django Tenants Documentation](https://django-tenants.readthedocs.io/)
- [PostgreSQL Multi-tenancy Guide](https://www.postgresql.org/docs/12/ddl-schemas.html)
- [R Markdown Guide](https://rmarkdown.rstudio.com/)

### C. Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-01-05 | Initial architecture document | Solutions Architect |

---

**Document Status**: ✅ Complete
**Next Review**: 2026-02-05
**Owner**: Solutions Architect
