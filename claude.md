# Claude Code Project Guide - PerfAnalysis Integrated Performance Monitoring Ecosystem

**Version**: 1.0
**Last Updated**: 2026-01-04
**Total Agents**: 16
**Project Status**: Active Development

---

## CRITICAL REQUIREMENT: Agent-First Workflow

**THIS IS MANDATORY AND NON-NEGOTIABLE**: Every request, every task, every question MUST begin with agent selection. This is not optional. This is not a suggestion. This is a **CRITICAL REQUIREMENT** that ensures correct routing, proper expertise application, and successful task completion.

### The Rule

```
┌─────────────────────────────────────────────────────────────┐
│ BEFORE YOU DO ANYTHING ELSE:                                 │
│                                                               │
│ 1. READ THE REQUEST                                          │
│ 2. IDENTIFY THE APPROPRIATE AGENT(S)                         │
│ 3. STATE WHICH AGENT(S) YOU ARE INVOKING                     │
│ 4. PROCEED WITH THE AGENT'S EXPERTISE                        │
│                                                               │
│ NO EXCEPTIONS. NO SHORTCUTS. AGENT SELECTION IS MANDATORY.   │
└─────────────────────────────────────────────────────────────┘
```

### Why This Matters

The PerfAnalysis ecosystem is a complex, multi-component system spanning:
- **3 programming languages** (Go, Python, R)
- **3 major frameworks** (Django, R Markdown, Go net/http)
- **2 database systems** (PostgreSQL, Oracle)
- **3 deployment environments** (Linux servers, Azure cloud, local development)

Without proper agent routing, you will:
- ❌ Apply Django patterns to Go code
- ❌ Use R optimization techniques on Python code
- ❌ Implement single-tenant solutions in multi-tenant systems
- ❌ Violate security boundaries between components
- ❌ Break data flow contracts between systems
- ❌ Deploy incorrect configurations to production

With proper agent routing, you will:
- ✅ Apply technology-specific best practices
- ✅ Maintain architectural boundaries
- ✅ Ensure cross-component compatibility
- ✅ Implement proper security measures
- ✅ Follow established patterns
- ✅ Deliver production-ready solutions

---

## Agent Selection Template

### Template for Single Agent Tasks

```
"As the [AGENT NAME], [specific task with context]."
```

**Examples**:
```
✅ CORRECT: "As the Go Backend Developer, add /proc/loadavg parsing to pcc."

❌ WRONG: "Add /proc/loadavg parsing to pcc."
(No agent specified - will result in generic, non-specialized advice)
```

### Template for Multi-Agent Tasks

```
"[AGENT 1] and [AGENT 2]: [collaborative task with context]."
```

**Examples**:
```
✅ CORRECT: "Integration Architect and Security Architect: Design the
            authenticated upload API between perfcollector2 and XATbackend."

❌ WRONG: "Design the upload API."
(No agents specified - will miss critical integration and security patterns)
```

### Template for Complex Workflows

```
"[AGENT 1]: [task 1]
 [AGENT 2]: [task 2 building on task 1]
 [AGENT 3]: [task 3 integrating results]"
```

**Examples**:
```
✅ CORRECT:
"Linux Systems Engineer: Identify metrics available in /proc/vmstat.
 Go Backend Developer: Implement parsing for those metrics in pcc.
 Data Quality Engineer: Add validation rules for the new metrics."

❌ WRONG:
"Add vmstat metrics to pcc."
(No workflow, no agents, no validation - incomplete solution)
```

---

## Agent Selection Decision Tree

Use this decision tree to select the correct agent(s):

```
START: What are you working on?
│
├─ "I'm working on perfcollector2 (Go code)"
│  └─► Primary: Go Backend Developer
│     Secondary: Linux Systems Engineer (for /proc parsing)
│
├─ "I'm working on XATbackend (Django/Python)"
│  └─► Primary: Backend Python Developer
│     Secondary: Django Tenants Specialist (for multi-tenancy)
│
├─ "I'm working on automated-Reporting (R code)"
│  └─► Primary: R Performance Expert
│     Secondary: Data Architect (for data transformation)
│
├─ "I'm integrating between components"
│  └─► Primary: Integration Architect
│     Secondary: Component-specific agents
│
├─ "I'm designing an API"
│  └─► Primary: API Architect
│     Secondary: Integration Architect, Security Architect
│
├─ "I'm dealing with security/authentication"
│  └─► Primary: Security Architect
│     Secondary: Component-specific agents
│
├─ "I'm designing database schema"
│  └─► Primary: Data Architect
│     Secondary: Time-Series Architect, Django Tenants Specialist
│
├─ "I'm deploying to production"
│  └─► Primary: DevOps Engineer
│     Secondary: Solutions Architect, Security Architect
│
├─ "I'm setting up automation/workflows"
│  └─► Primary: Automation Engineer
│     Secondary: Configuration Management Specialist
│
├─ "I'm troubleshooting data quality issues"
│  └─► Primary: Data Quality Engineer
│     Secondary: Component-specific agents
│
└─ "I'm new to the project / need overview"
   └─► Primary: Integration Architect
      Secondary: Solutions Architect
```

---

## Examples: Correct vs Incorrect Workflows

### Example 1: Adding New Metric Collection

#### ❌ INCORRECT Approach

```
User: "Add /proc/vmstat metrics to the system."

Claude: "Sure! I'll help you add vmstat metrics. Here's some code..."
```

**Why This Fails**:
- No agent selection
- No understanding of which component this affects
- No consideration of validation, storage, or visualization
- Generic code that won't follow project patterns
- Missing integration points

#### ✅ CORRECT Approach

```
User: "I need to add /proc/vmstat metrics to the system."

Claude: "I'll help you add /proc/vmstat metrics using the proper agent workflow:

1. Linux Systems Engineer: Identify available vmstat metrics
2. Go Backend Developer: Implement parsing in perfcollector2
3. Data Quality Engineer: Add validation rules
4. Integration Architect: Ensure proper upload format
5. Backend Python Developer: Update XATbackend schema
6. R Performance Expert: Add vmstat visualization to reports

Let's start:

As the Linux Systems Engineer: /proc/vmstat contains memory management metrics.
Key fields include: nr_free_pages, nr_inactive_anon, pgpgin, pgpgout...
[continues with proper expertise]"
```

**Why This Succeeds**:
- Identifies all required agents
- Follows data flow through all components
- Ensures validation and integration
- Applies component-specific expertise
- Delivers end-to-end solution

---

### Example 2: Implementing Upload Feature

#### ❌ INCORRECT Approach

```
User: "Implement file upload from perfcollector2 to XATbackend."

Claude: "Here's a simple HTTP POST request in Go..."
```

**Why This Fails**:
- No security considerations
- No multi-tenancy handling
- No error handling or retry logic
- No format specification
- Missing authentication

#### ✅ CORRECT Approach

```
User: "Implement file upload from perfcollector2 to XATbackend."

Claude: "As the Integration Architect: I'll coordinate this implementation
across multiple agents to ensure secure, reliable data transfer.

Integration Architect: Overall workflow design
Security Architect: Authentication and authorization
Go Backend Developer: Upload client implementation
Backend Python Developer: Upload endpoint implementation
Django Tenants Specialist: Multi-tenant data isolation
Data Quality Engineer: Upload validation

Step 1 - Integration Architect: Here's the data flow...
Step 2 - Security Architect: Use Bearer token authentication...
[continues with comprehensive solution]"
```

**Why This Succeeds**:
- Multi-agent collaboration
- Security built-in from the start
- Proper architectural design
- Component-specific implementations
- Complete end-to-end solution

---

### Example 3: Optimizing Slow Report

#### ❌ INCORRECT Approach

```
User: "My R report is slow."

Claude: "Try using vectorization instead of loops."
```

**Why This Fails**:
- Generic advice without profiling
- No understanding of data source
- No consideration of data.table vs data.frame
- Missing specific optimization techniques
- No measurement of improvement

#### ✅ CORRECT Approach

```
User: "My R report is taking 5 minutes to generate for 100K rows of CPU data."

Claude: "As the R Performance Expert: Let me analyze this performance issue.

First, I need to understand:
1. Are you using data.frame or data.table?
2. What operations are slowest?
3. Are you reading from database or CSV?

R Performance Expert: Use profvis to identify bottlenecks...
Data Architect: Consider pre-aggregation in the database...
[continues with specific, measurable optimizations]"
```

**Why This Succeeds**:
- Asks diagnostic questions
- Uses profiling tools
- Applies R-specific expertise
- Considers database optimization
- Provides measurable improvements

---

## Project Architecture

### System Overview

The PerfAnalysis ecosystem integrates three independent components into a unified performance monitoring solution:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PERFANALYSIS ECOSYSTEM                            │
│                                                                      │
│  "From Linux /proc to Actionable Performance Insights"              │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────┐         ┌──────────────────┐         ┌──────────────────┐
│  perfcollector2  │────────▶│   XATbackend     │────────▶│   automated-     │
│   (Go 1.21+)     │         │ (Django 3.2.3)   │         │   Reporting      │
│                  │         │                  │         │   (R 4.5.2)      │
│ ROLE:            │         │ ROLE:            │         │ ROLE:            │
│ Data Collection  │         │ User Portal      │         │ Visualization    │
│                  │         │ Data Storage     │         │ Analysis         │
│ COMPONENTS:      │         │                  │         │                  │
│ • pcc (client)   │         │ FEATURES:        │         │ FEATURES:        │
│ • pcd (server)   │         │ • Multi-tenancy  │         │ • R Markdown     │
│ • pcprocess      │         │ • User auth      │         │ • Time-series    │
│ • pcctl (admin)  │         │ • Machine mgmt   │         │ • Percentiles    │
│                  │         │ • PostgreSQL     │         │ • Radar charts   │
│ OUTPUT:          │         │ • Azure hosted   │         │ • HTML/PDF       │
│ JSON → CSV       │         │                  │         │                  │
└──────────────────┘         └──────────────────┘         └──────────────────┘
         │                            │                            │
         │                            │                            │
         ▼                            ▼                            ▼
   Linux /proc              PostgreSQL 12.2                   CSV Files
   System Metrics          + Oracle 26ai (future)            Visualization
```

### Data Flow Pipeline

```
STAGE 1: COLLECTION (perfcollector2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────┐
│ Linux Server    │  Target system being monitored
│ /proc files:    │
│ • /proc/stat    │  ← CPU metrics
│ • /proc/meminfo │  ← Memory usage
│ • /proc/diskstats│ ← Disk I/O
│ • /proc/net/dev │  ← Network stats
└────────┬────────┘
         │ Polled every 1-60 seconds
         │
         ▼
┌─────────────────┐
│ pcc (client)    │  Lightweight Go binary
│ Collects:       │
│ • CPU %         │
│ • Memory MB     │
│ • Disk IOPS     │
│ • Network Mbps  │
└────────┬────────┘
         │
         ├─► Mode 1: Local Storage
         │   └─► Saves to JSON file
         │       └─► pcprocess converts to CSV
         │
         └─► Mode 2: Trickle Upload
             └─► HTTP POST to pcd server
                 └─► pcd stores, pcprocess converts

OUTPUT: CSV files with performance metrics


STAGE 2: UPLOAD & STORAGE (XATbackend)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────┐
│ CSV Files       │  From perfcollector2
└────────┬────────┘
         │ HTTP POST /api/v1/performance/upload
         │ Auth: Bearer token
         │ Format: multipart/form-data
         │
         ▼
┌──────────────────────┐
│ XATbackend Portal    │  Django 3.2.3 application
│ /api/v1/performance/ │
│                      │
│ Features:            │
│ • Multi-tenant       │  ← Tenant isolation via django-tenants
│ • User authentication│  ← Django auth + API keys
│ • Machine management │  ← Register/manage monitored servers
│ • Data validation    │  ← Input validation & sanitization
└──────────┬───────────┘
           │
           │ Stores to database with tenant context
           │
           ▼
┌──────────────────────┐
│ PostgreSQL 12.2      │  Primary data store
│                      │
│ Schema per tenant:   │
│ • machines           │  ← Machine metadata
│ • performance_data   │  ← Time-series metrics
│ • users              │  ← User accounts
│ • api_keys           │  ← Authentication tokens
│                      │
│ Future: Oracle 26ai  │  ← Planned migration
└──────────┬───────────┘
           │
           │ Export via API or file download
           │
           ▼

OUTPUT: Queryable database, CSV export


STAGE 3: VISUALIZATION (automated-Reporting)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
┌─────────────────┐
│ CSV Export      │  From XATbackend or direct from perfcollector2
└────────┬────────┘
         │
         │ R reads CSV files
         │
         ▼
┌──────────────────────┐
│ R Markdown Report    │  reporting.Rmd (2,039 lines)
│                      │
│ Analysis:            │
│ • Time-series charts │  ← ggplot2 visualizations
│ • Percentile stats   │  ← 95th, 97.5th, 99th, 100th
│ • Resource breakdown │  ← Per-CPU, per-device analysis
│ • Radar charts       │  ← Multi-metric correlation
│ • Summary tables     │  ← Key metrics and stats
│                      │
│ Packages:            │
│ • ggplot2            │  ← Charting
│ • dplyr              │  ← Data manipulation
│ • data.table         │  ← High-performance operations
│ • lubridate          │  ← Date/time handling
│ • fmsb               │  ← Radar charts
└──────────┬───────────┘
           │
           │ Renders to output format
           │
           ▼
┌──────────────────────┐
│ HTML/PDF Reports     │  Final deliverable
│                      │
│ • Interactive HTML   │  ← Recommended format
│ • Printable PDF      │  ← Requires LaTeX
│ • Machine metadata   │  ← Context information
│ • Performance insights│ ← Actionable recommendations
└──────────────────────┘

OUTPUT: Performance analysis reports
```

---

## Component Architecture Details

### Component 1: perfcollector2 (Go-based Data Collector)

**Location**: `/Users/danmcdougal/projects/PerfAnalysis/perfcollector2/`

**Purpose**: Lightweight, efficient collection of Linux performance metrics from /proc filesystem

**Technology Stack**:
- **Language**: Go 1.21+
- **Frameworks**: net/http (HTTP server), encoding/json (data serialization)
- **Data Source**: Linux /proc filesystem
- **Output**: JSON (raw) → CSV (processed)

**Components**:

1. **pcc (Performance Collector Client)**
   - Purpose: Runs on monitored servers to collect metrics
   - Operation Modes:
     - Local mode: Saves JSON to file
     - Trickle mode: Streams to pcd server via HTTP
   - Configuration: Environment variables (PCC_DURATION, PCC_FREQUENCY, PCC_COLLECTION)
   - Metrics Collected:
     - CPU: /proc/stat (user, system, idle, iowait per core)
     - Memory: /proc/meminfo (total, used, available, buffers, cache)
     - Disk: /proc/diskstats (reads, writes, IOPS, throughput)
     - Network: /proc/net/dev (RX/TX bytes, packets, errors)

2. **pcd (Performance Collector Daemon)**
   - Purpose: Backend server to receive trickled data
   - Endpoint: HTTP POST /v1/ping
   - Authentication: API keys stored in ~/.pcd/apikeys
   - Configuration: Environment variables (LISTENADDRESS, PCD_LOGLEVEL)
   - Security: API key validation (minimum 8 characters)

3. **pcprocess (Performance Data Processor)**
   - Purpose: Convert raw JSON collections to CSV format
   - Input: JSON file from pcc or pcd
   - Output: CSV file with standardized columns
   - Configuration: Environment variables (PCR_COLLECTION, PCR_OUTDIR)

4. **pcctl (Performance Collector Controller)**
   - Purpose: Admin tool and API reference client
   - Functions: API testing, administration tasks

**Key Files**:
- `cmd/pcc/main.go` - Client implementation
- `cmd/pcd/main.go` - Server implementation
- `cmd/pcprocess/main.go` - Processor implementation
- `cmd/pcctl/main.go` - Controller implementation
- `Makefile` - Build configuration

**Relevant Agents**:
- Primary: Go Backend Developer
- Secondary: Linux Systems Engineer, Data Quality Engineer, Configuration Management Specialist

---

### Component 2: XATbackend (Django Multi-Tenant Portal)

**Location**: `/Users/danmcdougal/projects/PerfAnalysis/XATbackend/`

**Purpose**: Secure, multi-tenant web portal for user authentication, machine management, and data storage

**Technology Stack**:
- **Language**: Python 3.x
- **Framework**: Django 3.2.3
- **Multi-Tenancy**: django-tenants 3.3.1
- **Database**: PostgreSQL 12.2 (current), Oracle 26ai (planned)
- **Deployment**: Azure App Service
- **Authentication**: Django auth + API keys

**Architecture**:

1. **Multi-Tenancy Model** (django-tenants)
   - Schema-based isolation (one PostgreSQL schema per tenant)
   - Shared apps: User auth, tenant management
   - Tenant apps: Performance data, machine registry
   - Domain routing: tenant.portal.example.com

2. **Core Applications**:
   - User authentication and authorization
   - Tenant management and provisioning
   - Machine registration and metadata
   - Performance data upload API
   - Data export and visualization integration

3. **API Endpoints** (Planned/In Development):
   - `POST /api/v1/performance/upload` - Upload CSV data
   - `GET /api/v1/performance/export` - Export data for reporting
   - `POST /api/v1/machines/register` - Register new machine
   - `GET /api/v1/machines/list` - List tenant's machines
   - `POST /api/v1/auth/token` - Generate API token

4. **Database Schema**:
   - Public schema: Tenants, shared config
   - Tenant schemas: Machines, performance_data, users
   - Time-series optimization: Partitioning by timestamp (future)

5. **Security Features**:
   - Tenant isolation via django-tenants
   - API key authentication for uploads
   - Django CSRF protection for web UI
   - HTTPS enforcement in production
   - Input validation and sanitization

**Deployment**:
- Platform: Azure App Service
- Web server: Gunicorn
- Reverse proxy: Nginx (configured by Azure)
- Static files: Azure Blob Storage
- Database: Azure Database for PostgreSQL

**Key Files**:
- `core/settings.py` - Django configuration
- `core/urls.py` - URL routing
- `apps/` - Django applications
- `requirements.txt` - Python dependencies
- `.azure/` - Azure deployment configuration (if exists)

**Relevant Agents**:
- Primary: Backend Python Developer, Django Tenants Specialist
- Secondary: Security Architect, DevOps Engineer, Data Architect, API Architect

---

### Component 3: automated-Reporting (R-based Visualization)

**Location**: `/Users/danmcdougal/projects/PerfAnalysis/automated-Reporting/`

**Purpose**: Generate comprehensive performance analysis reports with time-series visualizations, percentile analysis, and actionable insights

**Technology Stack**:
- **Language**: R 4.5.2+
- **Reporting**: R Markdown (rmarkdown package)
- **Visualization**: ggplot2 (charts), fmsb (radar charts)
- **Data Manipulation**: dplyr (transformations), data.table (performance)
- **Date/Time**: lubridate
- **Output**: HTML (recommended), PDF (requires LaTeX)
- **Future**: Oracle 26ai integration for direct database access

**Architecture**:

1. **Main Report** (`reporting.Rmd`):
   - 2,039 lines of R Markdown
   - Input: CSV files from perfcollector2 or XATbackend
   - Output: HTML/PDF with comprehensive analysis
   - Configuration: Hardcoded variables (lines 24-30) - planned for replacement

2. **Hardcoded Configuration** (Current Limitation):
   ```r
   storeVol <- "sda"              # Storage device name
   netIface <- "ens33"            # Network interface name
   machName <- "machine001"       # Machine identifier
   UUID <- "0001-001-002"         # Unique identifier
   loc <- ("testData/proc/")      # Data directory path
   ```
   - Issue: Must manually edit for each machine
   - Solution: YAML configuration system (planned)

3. **Report Sections**:
   - Executive Summary: Key metrics and overall health
   - CPU Analysis: Per-core utilization, percentiles, time-series
   - Memory Analysis: Usage patterns, buffer/cache breakdown
   - Disk I/O Analysis: IOPS, throughput, latency proxy
   - Network Analysis: Bandwidth utilization, packet rates
   - Radar Charts: Multi-metric correlation visualization
   - Detailed Tables: Raw statistics and percentile breakdowns

4. **Data Flow**:
   - Input: CSV files with columns (timestamp, metric_name, metric_value)
   - Processing: data.frame operations (planned: data.table migration)
   - Visualization: ggplot2 + custom themes
   - Output: Self-contained HTML or PDF report

5. **R Packages** (DESCRIPTION file):
   - ggplot2 (>= 3.4.0) - Visualization
   - dplyr (>= 1.1.0) - Data manipulation
   - lubridate (>= 1.9.0) - Date/time handling
   - fmsb (>= 0.7.6) - Radar charts
   - knitr (>= 1.45) - Report knitting
   - rmarkdown (>= 2.20) - Report rendering

6. **Planned Enhancements**:
   - CLI interface (reporting_cli.R)
   - YAML configuration system
   - Device auto-detection
   - Data validation framework
   - Oracle 26ai direct integration
   - Multi-machine comparison reports

**Test Data**:
- Location: `testData/proc/`
- Files: stat, meminfo, diskstats, net/dev
- Format: Matches Linux /proc filesystem structure

**Key Files**:
- `reporting.Rmd` - Main report template
- `DESCRIPTION` - R package dependencies
- `renv_init.R` - Reproducible environment setup
- `testData/` - Sample data for testing
- `agents/` - 21 specialized agents (shared with parent project)

**Relevant Agents**:
- Primary: R Performance Expert
- Secondary: Data Architect, Time-Series Architect, Oracle Developer (future), Automation Engineer, Configuration Management Specialist

---

## Integration Points & Data Contracts

### Integration Point 1: perfcollector2 → XATbackend

**Purpose**: Upload collected performance data to the multi-tenant portal for storage and management

**Protocol**: HTTP POST with multipart/form-data

**Endpoint**: `POST /api/v1/performance/upload`

**Authentication**: Bearer token (user-specific API key)

**Request Format**:
```http
POST /api/v1/performance/upload HTTP/1.1
Host: portal.example.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="perf_server01_20260104_120000.csv"
Content-Type: text/csv

timestamp,machine_id,cpu_user,cpu_system,cpu_idle,mem_total,mem_used,...
1704369600,server01,25.5,10.2,64.3,32768,16384,...
1704369601,server01,26.1,10.5,63.4,32768,16450,...
------WebKitFormBoundary
Content-Disposition: form-data; name="machine_id"

server01
------WebKitFormBoundary
Content-Disposition: form-data; name="tenant_id"

tenant-abc-123-def
------WebKitFormBoundary--
```

**Response Format** (Success):
```json
{
  "status": "success",
  "message": "Performance data uploaded successfully",
  "records_processed": 86400,
  "machine_id": "server01",
  "tenant_id": "tenant-abc-123-def",
  "upload_timestamp": "2026-01-04T12:00:00Z",
  "data_range": {
    "start": "2026-01-04T00:00:00Z",
    "end": "2026-01-04T23:59:59Z"
  }
}
```

**Response Format** (Error):
```json
{
  "status": "error",
  "error_code": "INVALID_CSV_FORMAT",
  "message": "Missing required column: cpu_user",
  "details": {
    "found_columns": ["timestamp", "machine_id", "cpu_system"],
    "missing_columns": ["cpu_user", "mem_total", "mem_used"]
  }
}
```

**CSV Format Requirements**:
- **Required Columns**:
  - `timestamp` (Unix epoch or ISO 8601)
  - `machine_id` (string, matches registered machine)
  - `cpu_user`, `cpu_system`, `cpu_idle` (percentages)
  - `mem_total`, `mem_used`, `mem_available` (MB)
  - `disk_read_bytes`, `disk_write_bytes` (bytes)
  - `net_rx_bytes`, `net_tx_bytes` (bytes)

- **Optional Columns**:
  - `cpu_iowait`, `cpu_steal` (percentages)
  - `mem_buffers`, `mem_cached` (MB)
  - `disk_read_ops`, `disk_write_ops` (count)
  - `net_rx_packets`, `net_tx_packets` (count)

- **Constraints**:
  - Maximum file size: 100MB
  - Maximum records: 1,000,000 per upload
  - Timestamp must be within last 30 days (configurable)

**Error Handling**:
- 400 Bad Request: Invalid CSV format, missing columns
- 401 Unauthorized: Invalid or missing API token
- 403 Forbidden: Machine not registered to tenant
- 413 Payload Too Large: File exceeds size limit
- 429 Too Many Requests: Rate limit exceeded
- 500 Internal Server Error: Database or processing error

**Security Considerations**:
- API key must be generated per machine
- API key rotation every 90 days (recommended)
- HTTPS required (HTTP redirects to HTTPS)
- CSV content sanitization (SQL injection prevention)
- Tenant validation before data storage

**Relevant Agents**:
- Integration Architect (workflow design)
- Go Backend Developer (client implementation)
- Backend Python Developer (server endpoint)
- Security Architect (authentication/authorization)
- Django Tenants Specialist (tenant isolation)
- Data Quality Engineer (validation rules)

---

### Integration Point 2: XATbackend → automated-Reporting

**Purpose**: Export performance data from portal for visualization and analysis

**Method**: CSV file export or REST API (future)

**Export Endpoint** (Planned): `GET /api/v1/performance/export`

**Request Format**:
```http
GET /api/v1/performance/export?machine_id=server01&start=2026-01-04T00:00:00Z&end=2026-01-04T23:59:59Z HTTP/1.1
Host: portal.example.com
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Accept: text/csv
```

**Response Format** (CSV):
```csv
timestamp,machine_id,cpu_user,cpu_system,cpu_idle,cpu_iowait,mem_total,mem_used,mem_available,mem_buffers,mem_cached,disk_read_bytes,disk_write_bytes,disk_read_ops,disk_write_ops,net_rx_bytes,net_tx_bytes,net_rx_packets,net_tx_packets
1704369600,server01,25.5,10.2,64.3,0.0,32768,16384,16384,512,8192,1048576,2097152,100,200,1073741824,536870912,100000,50000
```

**CSV Format Requirements** (for R consumption):
- Column names must match R variable expectations
- Timestamps in Unix epoch or ISO 8601
- Numeric fields without thousand separators
- UTF-8 encoding
- CRLF or LF line endings (both supported)

**Alternative: Manual Export**:
- User downloads CSV from web portal
- Places in `testData/proc/` directory (or custom location)
- Updates `reporting.Rmd` configuration (lines 24-30)
- Runs `rmarkdown::render("reporting.Rmd")`

**R Integration**:
```r
# R reads the exported CSV
data <- read.csv("export_server01_20260104.csv", stringsAsFactors = FALSE)

# Convert timestamp
data$timestamp <- as.POSIXct(data$timestamp, origin="1970-01-01")

# Process and visualize
# ... (reporting.Rmd logic)
```

**Future: Direct Database Connection**:
- R connects directly to Oracle 26ai database
- Uses ROracle or DBI + odbc packages
- Eliminates CSV intermediate step
- Enables real-time report generation

**Relevant Agents**:
- Backend Python Developer (export endpoint)
- R Performance Expert (R integration)
- Integration Architect (format specification)
- Data Architect (data transformation)
- Data Quality Engineer (export validation)

---

### Integration Point 3: perfcollector2 → automated-Reporting (Direct)

**Purpose**: Bypass portal for development, testing, or standalone deployments

**Method**: Direct CSV file access

**Workflow**:
1. Run `pcc` in local mode → generates JSON
2. Run `pcprocess` → converts JSON to CSV
3. Place CSV in `testData/proc/` or custom directory
4. Update `reporting.Rmd` configuration
5. Run `rmarkdown::render("reporting.Rmd")`

**Advantages**:
- No network dependency
- No authentication required
- Faster for single-machine testing
- Simpler deployment for edge cases

**Disadvantages**:
- No centralized storage
- No multi-tenant support
- Manual file management
- No web portal access

**Use Cases**:
- Development and testing
- Standalone server monitoring
- Air-gapped environments
- Quick troubleshooting

**Relevant Agents**:
- Go Backend Developer (CSV format)
- R Performance Expert (CSV consumption)
- Integration Architect (workflow design)

---

## Agent Registry (16 Specialized Agents)

### Backend Development (3 agents)

#### 1. Go Backend Developer
- **File**: `agents/backend/go-backend-developer.md`
- **Component**: perfcollector2
- **Expertise**:
  - Go programming (1.21+)
  - HTTP client/server development
  - /proc filesystem parsing
  - JSON/CSV data serialization
  - Concurrent programming
  - Error handling patterns
- **Key Responsibilities**:
  - Implement pcc client for metric collection
  - Implement pcd server for trickle mode
  - Develop pcprocess for data transformation
  - CSV format standardization
  - Upload client for XATbackend integration
- **Typical Tasks**:
  - "Add /proc/vmstat parsing to pcc"
  - "Implement retry logic for upload failures"
  - "Optimize memory usage in pcprocess"

#### 2. Backend Python Developer
- **File**: `agents/backend/backend-python-developer.md`
- **Component**: XATbackend
- **Expertise**:
  - Django 3.2.3 development
  - REST API design and implementation
  - Django ORM optimization
  - PostgreSQL integration
  - Django views, forms, templates
  - Async task processing (Celery)
- **Key Responsibilities**:
  - Implement upload API endpoint
  - Develop export functionality
  - Machine registration and management
  - User authentication and authorization
  - Data validation and sanitization
- **Typical Tasks**:
  - "Create upload endpoint for performance data"
  - "Implement CSV export with date filtering"
  - "Add machine registration API"

#### 3. Django Tenants Specialist
- **File**: `agents/backend/django-tenants-specialist.md`
- **Component**: XATbackend
- **Expertise**:
  - django-tenants 3.3.1 configuration
  - Schema-based multi-tenancy
  - Tenant isolation and security
  - Domain routing
  - Shared vs tenant apps
  - Tenant provisioning and migration
- **Key Responsibilities**:
  - Configure multi-tenant architecture
  - Ensure data isolation between tenants
  - Implement tenant-aware queries
  - Domain/subdomain routing setup
  - Tenant onboarding workflows
- **Typical Tasks**:
  - "Fix cross-tenant data leak in performance queries"
  - "Implement tenant provisioning workflow"
  - "Configure domain routing for new tenant"

---

### Operational & Automation (4 agents)

#### 4. Linux Systems Engineer
- **File**: `agents/operational/linux-systems-engineer.md`
- **Component**: perfcollector2
- **Expertise**:
  - /proc filesystem internals
  - System metrics and monitoring
  - Device discovery (storage, network)
  - sysstat utilities
  - Performance tuning
  - Shell scripting
- **Key Responsibilities**:
  - Identify available metrics in /proc
  - Design device auto-detection logic
  - Troubleshoot metric collection issues
  - Validate metric accuracy
  - Performance baseline analysis
- **Typical Tasks**:
  - "What metrics are available in /proc/vmstat?"
  - "Design auto-detection for busiest disk"
  - "Explain /proc/stat CPU time accounting"

#### 5. Automation Engineer
- **File**: `agents/operational/automation-engineer.md`
- **Component**: All
- **Expertise**:
  - CLI design and development
  - Workflow orchestration
  - Job scheduling (cron, systemd timers)
  - Batch processing
  - Error handling and retry logic
  - Logging and monitoring
- **Key Responsibilities**:
  - Design CLI interfaces
  - Implement end-to-end pipelines
  - Set up automated scheduling
  - Error notification systems
  - Workflow documentation
- **Typical Tasks**:
  - "Create CLI wrapper for reporting.Rmd"
  - "Design automated upload pipeline"
  - "Implement systemd timer for pcc collection"

#### 6. Configuration Management Specialist
- **File**: `agents/operational/configuration-management-specialist.md`
- **Component**: All
- **Expertise**:
  - YAML/JSON configuration files
  - Environment variables
  - Secrets management
  - Configuration validation
  - Inventory management
  - Template-based configs
- **Key Responsibilities**:
  - Design configuration systems
  - Implement secrets management
  - Create configuration schemas
  - Validate configuration files
  - Machine inventory management
- **Typical Tasks**:
  - "Replace hardcoded values in reporting.Rmd with YAML config"
  - "Design secure API key storage"
  - "Create machine inventory system"

#### 7. Data Quality Engineer
- **File**: `agents/operational/data-quality-engineer.md`
- **Component**: All
- **Expertise**:
  - Data validation frameworks
  - Quality metrics and scorecards
  - Input sanitization
  - Error detection patterns
  - Data profiling
  - Anomaly detection
- **Key Responsibilities**:
  - Design validation rules
  - Implement quality checks
  - Detect data anomalies
  - Handle missing/corrupt data
  - Quality reporting
- **Typical Tasks**:
  - "Add validation for CPU metrics (must be 0-100%)"
  - "Detect and handle counter rollover"
  - "Implement data quality scorecard"

---

### Performance (1 agent)

#### 8. R Performance Expert
- **File**: `agents/performance/r-performance-expert.md`
- **Component**: automated-Reporting
- **Expertise**:
  - R optimization and profiling
  - Vectorization techniques
  - data.table vs data.frame
  - ggplot2 visualization
  - R Markdown best practices
  - Memory management
  - Parallel processing
- **Key Responsibilities**:
  - Optimize slow R code
  - Design efficient visualizations
  - Implement data.table operations
  - Profile code with profvis
  - Cache expensive computations
- **Typical Tasks**:
  - "Optimize this data.frame operation processing 100K rows"
  - "Convert dplyr code to data.table"
  - "Profile reporting.Rmd and identify bottlenecks"

---

### Database & Data Architecture (3 agents)

#### 9. Data Architect
- **File**: `agents/database/data-architect.md`
- **Component**: All
- **Expertise**:
  - Database schema design
  - Time-series data modeling
  - Query optimization
  - Indexing strategies
  - Partitioning and sharding
  - Data normalization
  - ETL pipelines
- **Key Responsibilities**:
  - Design database schemas
  - Optimize queries
  - Plan partitioning strategies
  - Data transformation logic
  - Migration planning
- **Typical Tasks**:
  - "Design PostgreSQL schema for performance data"
  - "Optimize query for 90-day metric aggregation"
  - "Plan Oracle migration strategy"

#### 10. Time-Series Architect
- **File**: `agents/database/time-series-architect.md`
- **Component**: All
- **Expertise**:
  - Time-series database design
  - Metric aggregation (rollups)
  - Retention policies
  - Partitioning by time
  - Continuous aggregates
  - Downsampling strategies
  - Time-series specific indexes
- **Key Responsibilities**:
  - Design time-series storage
  - Implement rollup strategies
  - Configure retention policies
  - Optimize time-range queries
  - Partitioning by timestamp
- **Typical Tasks**:
  - "Design partitioning for 1-second granularity data"
  - "Implement hourly rollups with 90-day retention"
  - "Optimize query for percentile calculations"

#### 11. Oracle Developer
- **File**: `agents/database/agent-oracle-developer.md`
- **Component**: automated-Reporting (future)
- **Expertise**:
  - PL/SQL programming
  - Oracle 26ai features
  - Stored procedures and functions
  - Oracle-specific optimization
  - Vector search (future)
  - Oracle Free edition
- **Key Responsibilities**:
  - Implement Oracle integration
  - Write PL/SQL procedures
  - Optimize Oracle queries
  - Design Oracle schemas
  - Connection pooling
- **Typical Tasks**:
  - "Implement R connection to Oracle 26ai"
  - "Design stored procedure for metric aggregation"
  - "Optimize Oracle query for reporting"

---

### Architecture & Infrastructure (5 agents)

#### 12. Integration Architect
- **File**: `agents/integration/integration-architect.md`
- **Component**: All (cross-cutting)
- **Expertise**:
  - Multi-system integration
  - Data pipeline orchestration
  - API contract design
  - End-to-end data flow
  - Error propagation
  - Integration testing
  - System monitoring
- **Key Responsibilities**:
  - Design integration workflows
  - Define API contracts
  - Orchestrate multi-component tasks
  - Troubleshoot data flow issues
  - Integration documentation
- **Typical Tasks**:
  - "Design end-to-end upload workflow"
  - "Troubleshoot data missing in reports"
  - "Document integration points"
- **When to Consult**:
  - New to the project (system overview)
  - Working across multiple components
  - Debugging end-to-end issues
  - Designing new integrations

#### 13. API Architect
- **File**: `agents/architecture/api-architect.md`
- **Component**: All
- **Expertise**:
  - REST API design
  - API versioning
  - Endpoint structure
  - Request/response formats
  - API documentation (OpenAPI)
  - Rate limiting
  - Pagination
- **Key Responsibilities**:
  - Design REST APIs
  - Define endpoint structure
  - Version APIs
  - Document APIs
  - Design error responses
- **Typical Tasks**:
  - "Design upload API endpoint structure"
  - "Implement API versioning strategy"
  - "Create OpenAPI specification"

#### 14. Security Architect
- **File**: `agents/architecture/security-architect.md`
- **Component**: All
- **Expertise**:
  - OWASP Top 10
  - Authentication and authorization
  - API key management
  - Multi-tenant security
  - Data encryption
  - HTTPS/TLS
  - Input validation
  - SQL injection prevention
- **Key Responsibilities**:
  - Design authentication systems
  - Implement authorization logic
  - Security audits
  - Vulnerability assessment
  - Secure API design
- **Typical Tasks**:
  - "Implement API key generation and validation"
  - "Audit upload endpoint for SQL injection"
  - "Design tenant isolation security"

#### 15. Solutions Architect
- **File**: `agents/architecture/solutions-architect-sais.md`
- **Component**: All
- **Expertise**:
  - System architecture
  - Azure cloud architecture
  - Scalability design
  - High availability (HA)
  - Disaster recovery (DR)
  - Multi-region deployment
  - Cost optimization
- **Key Responsibilities**:
  - Design overall architecture
  - Plan Azure deployment
  - Scalability strategies
  - HA/DR planning
  - Cost analysis
- **Typical Tasks**:
  - "Design scalable architecture for 1000+ machines"
  - "Plan Azure deployment architecture"
  - "Design disaster recovery strategy"

#### 16. DevOps Engineer
- **File**: `agents/architecture/devops-engineer.md`
- **Component**: XATbackend (primarily)
- **Expertise**:
  - Docker containerization
  - Azure App Service
  - GitHub Actions CI/CD
  - Monitoring and logging
  - Infrastructure as Code
  - Deployment automation
- **Key Responsibilities**:
  - Containerize applications
  - Set up CI/CD pipelines
  - Deploy to Azure
  - Configure monitoring
  - Automate deployments
- **Typical Tasks**:
  - "Create Dockerfile for XATbackend"
  - "Set up GitHub Actions for Django deployment"
  - "Configure Azure Application Insights"

---

## Quick Reference Tables

### Table 1: Agent Selection by Technology

| Technology | Primary Agent | Secondary Agents |
|------------|---------------|------------------|
| **Go programming** | Go Backend Developer | Linux Systems Engineer, Data Quality Engineer |
| **Python/Django** | Backend Python Developer | Django Tenants Specialist, Security Architect |
| **django-tenants** | Django Tenants Specialist | Backend Python Developer, Data Architect |
| **R/R Markdown** | R Performance Expert | Data Architect, Time-Series Architect |
| **PostgreSQL** | Data Architect | Django Tenants Specialist, Time-Series Architect |
| **Oracle 26ai** | Oracle Developer | Data Architect, R Performance Expert |
| **Linux /proc** | Linux Systems Engineer | Go Backend Developer, Data Quality Engineer |
| **Azure deployment** | DevOps Engineer | Solutions Architect, Security Architect |
| **Docker** | DevOps Engineer | Solutions Architect |
| **REST API** | API Architect | Integration Architect, Security Architect |
| **Authentication** | Security Architect | Backend Python Developer, Go Backend Developer |
| **Configuration** | Configuration Management Specialist | Automation Engineer |
| **Data validation** | Data Quality Engineer | Component-specific agents |
| **Automation/CLI** | Automation Engineer | Configuration Management Specialist |
| **Time-series DB** | Time-Series Architect | Data Architect |
| **ggplot2/charts** | R Performance Expert | - |
| **Workflow orchestration** | Automation Engineer | Integration Architect |
| **Multi-tenancy** | Django Tenants Specialist | Security Architect |

---

### Table 2: Agent Selection by Task Type

| Task Type | Primary Agent | Supporting Agents | Example |
|-----------|---------------|-------------------|---------|
| **Add new /proc metric** | Linux Systems Engineer | Go Backend Developer, Data Quality Engineer | "Add /proc/vmstat to collection" |
| **Optimize Go code** | Go Backend Developer | - | "Reduce memory usage in pcprocess" |
| **Implement upload** | Integration Architect | Go Backend Developer, Backend Python Developer, Security Architect | "Implement CSV upload to portal" |
| **Fix multi-tenancy bug** | Django Tenants Specialist | Backend Python Developer | "Fix cross-tenant data leak" |
| **Optimize R report** | R Performance Expert | Data Architect | "Speed up 100K row processing" |
| **Design database schema** | Data Architect | Time-Series Architect, Django Tenants Specialist | "Design schema for metrics" |
| **Set up authentication** | Security Architect | Backend Python Developer, Go Backend Developer | "Implement API key auth" |
| **Deploy to production** | DevOps Engineer | Solutions Architect, Security Architect | "Deploy XATbackend to Azure" |
| **Create CLI tool** | Automation Engineer | Configuration Management Specialist | "Build reporting CLI" |
| **Validate data quality** | Data Quality Engineer | Component-specific agents | "Detect invalid CPU values" |
| **Design REST API** | API Architect | Integration Architect, Security Architect | "Design export API" |
| **Configure automation** | Automation Engineer | Configuration Management Specialist | "Set up cron for collection" |
| **Troubleshoot integration** | Integration Architect | All component agents | "Data not appearing in reports" |
| **Plan Oracle migration** | Oracle Developer | Data Architect, R Performance Expert | "Migrate from CSV to Oracle" |
| **Design partitioning** | Time-Series Architect | Data Architect | "Partition by month" |
| **Architect system** | Solutions Architect | Integration Architect, Security Architect | "Design for 1000 machines" |

---

### Table 3: Agent Selection by Component

| Component | Task | Primary Agent | Secondary Agents |
|-----------|------|---------------|------------------|
| **perfcollector2** | Implement collection | Go Backend Developer | Linux Systems Engineer |
| **perfcollector2** | Parse /proc files | Linux Systems Engineer | Go Backend Developer |
| **perfcollector2** | Upload data | Go Backend Developer | Integration Architect, Security Architect |
| **perfcollector2** | Optimize performance | Go Backend Developer | - |
| **perfcollector2** | Configure collection | Configuration Management Specialist | Automation Engineer |
| **XATbackend** | Django development | Backend Python Developer | - |
| **XATbackend** | Multi-tenancy | Django Tenants Specialist | Backend Python Developer |
| **XATbackend** | Upload endpoint | Backend Python Developer | Security Architect, Integration Architect |
| **XATbackend** | Database schema | Data Architect | Django Tenants Specialist, Time-Series Architect |
| **XATbackend** | Deploy to Azure | DevOps Engineer | Solutions Architect |
| **XATbackend** | Security | Security Architect | Django Tenants Specialist |
| **automated-Reporting** | Optimize R code | R Performance Expert | - |
| **automated-Reporting** | Add visualizations | R Performance Expert | Data Architect |
| **automated-Reporting** | Oracle integration | Oracle Developer | R Performance Expert, Data Architect |
| **automated-Reporting** | CLI interface | Automation Engineer | R Performance Expert |
| **automated-Reporting** | Configuration | Configuration Management Specialist | R Performance Expert |
| **All components** | Integration | Integration Architect | Component-specific agents |
| **All components** | API design | API Architect | Integration Architect, Security Architect |
| **All components** | Security | Security Architect | Component-specific agents |
| **All components** | Architecture | Solutions Architect | Integration Architect |
| **All components** | Automation | Automation Engineer | Configuration Management Specialist |
| **All components** | Data quality | Data Quality Engineer | Component-specific agents |

---

### Table 4: Agent Selection by Problem Domain

| Problem Domain | Symptoms | Primary Agent | Secondary Agents | Investigation Steps |
|----------------|----------|---------------|------------------|---------------------|
| **Slow data collection** | pcc taking too long | Go Backend Developer | Linux Systems Engineer | 1. Profile Go code 2. Check /proc read latency 3. Optimize parsing |
| **Upload failures** | CSV not reaching portal | Integration Architect | Go Backend Developer, Backend Python Developer | 1. Check network 2. Validate auth 3. Check logs 4. Verify endpoint |
| **Cross-tenant data leak** | User sees other tenant data | Django Tenants Specialist | Security Architect | 1. Audit queries 2. Check tenant context 3. Review middleware |
| **Slow R reports** | reporting.Rmd takes minutes | R Performance Expert | Data Architect | 1. Profile with profvis 2. Check data.frame vs data.table 3. Optimize I/O |
| **Database performance** | Queries timeout | Data Architect | Time-Series Architect | 1. EXPLAIN query 2. Check indexes 3. Review partitioning |
| **API errors** | 400/500 responses | API Architect | Integration Architect, Backend Python Developer | 1. Check request format 2. Review validation 3. Check logs |
| **Security vulnerability** | Potential exploit | Security Architect | Component-specific agents | 1. Audit code 2. Run security scan 3. Review auth |
| **Deployment issues** | Azure deployment fails | DevOps Engineer | Solutions Architect | 1. Check logs 2. Validate config 3. Review Azure settings |
| **Configuration errors** | Hardcoded values breaking | Configuration Management Specialist | Automation Engineer | 1. Identify config 2. Design YAML schema 3. Implement loader |
| **Data validation errors** | Invalid metrics | Data Quality Engineer | Component-specific agents | 1. Check validation rules 2. Review data source 3. Add checks |
| **Missing data in pipeline** | Data collected but not in reports | Integration Architect | All component agents | 1. Trace data flow 2. Check each stage 3. Verify formats |
| **Memory issues** | OOM errors | Component-specific agent | - | 1. Profile memory 2. Check leaks 3. Optimize allocations |
| **Network timeouts** | HTTP requests failing | Integration Architect | Security Architect | 1. Check connectivity 2. Review timeouts 3. Add retries |
| **Time-series gaps** | Missing timestamps | Time-Series Architect | Data Quality Engineer | 1. Check collection frequency 2. Review partitioning 3. Validate timestamps |

---

## Common Integration Scenarios

### Scenario 1: Complete End-to-End Setup (New Deployment)

**Goal**: Set up the entire PerfAnalysis ecosystem from scratch

**Agent Workflow**:

1. **Solutions Architect**: Design overall architecture
   - "Solutions Architect: Design the architecture for monitoring 50 Linux servers with data retention of 30 days and reporting every 24 hours."
   - Deliverable: Architecture diagram, component sizing, network topology

2. **Security Architect**: Plan security implementation
   - "Security Architect: Design authentication and authorization for the multi-tenant portal with API key-based machine authentication."
   - Deliverable: Security architecture, auth flows, key management strategy

3. **Linux Systems Engineer**: Identify metrics to collect
   - "Linux Systems Engineer: Identify critical performance metrics from /proc for CPU, memory, disk, and network monitoring."
   - Deliverable: Metrics list, collection frequency recommendations

4. **Go Backend Developer**: Implement perfcollector2
   - "Go Backend Developer: Implement pcc to collect the metrics identified by the Linux Systems Engineer."
   - Deliverable: pcc binary with metric collection

5. **Configuration Management Specialist**: Set up configuration system
   - "Configuration Management Specialist: Design configuration system for perfcollector2 with machine inventory and collection parameters."
   - Deliverable: YAML config schema, inventory file, config loader

6. **Data Architect**: Design database schema
   - "Data Architect and Django Tenants Specialist: Design PostgreSQL schema for multi-tenant performance data storage with proper time-series partitioning."
   - Deliverable: DDL scripts, indexing strategy, partitioning plan

7. **Backend Python Developer**: Implement XATbackend
   - "Backend Python Developer: Create Django application with upload endpoint, machine management, and user authentication."
   - Deliverable: Django app, API endpoints, admin interface

8. **Django Tenants Specialist**: Configure multi-tenancy
   - "Django Tenants Specialist: Implement tenant isolation with domain routing and schema-based separation."
   - Deliverable: Multi-tenant configuration, middleware, domain routing

9. **Integration Architect**: Design and test data flow
   - "Integration Architect: Design the complete data flow from pcc collection through XATbackend storage to automated-Reporting visualization."
   - Deliverable: Integration documentation, test plan, validation scripts

10. **R Performance Expert**: Set up reporting
    - "R Performance Expert: Configure automated-Reporting to consume data from XATbackend and generate performance reports."
    - Deliverable: Configured reporting.Rmd, sample reports, documentation

11. **Automation Engineer**: Implement automation
    - "Automation Engineer: Create systemd timers for pcc collection, upload workflows, and scheduled reporting."
    - Deliverable: Systemd units, cron jobs, error handling

12. **DevOps Engineer**: Deploy to production
    - "DevOps Engineer: Deploy XATbackend to Azure App Service with PostgreSQL, configure monitoring, and set up CI/CD."
    - Deliverable: Azure deployment, monitoring dashboards, CI/CD pipeline

13. **Data Quality Engineer**: Implement validation
    - "Data Quality Engineer: Add data validation at collection, upload, and reporting stages with quality metrics."
    - Deliverable: Validation rules, quality scorecard, alerting

**Timeline**: 4-6 weeks for full implementation

---

### Scenario 2: Adding a New Machine to Existing System

**Goal**: Register and start monitoring a new Linux server

**Agent Workflow**:

1. **Configuration Management Specialist**: Add machine to inventory
   - "Configuration Management Specialist: Add server 'web-prod-05' to the machine inventory with collection parameters."
   - Deliverable: Updated inventory file, machine configuration

2. **Security Architect**: Generate API key
   - "Security Architect: Generate API key for machine 'web-prod-05' with proper scope and expiration."
   - Deliverable: API key, secure storage instructions

3. **Linux Systems Engineer**: Install pcc on server
   - "Linux Systems Engineer: Install and configure pcc on 'web-prod-05' for metric collection every 15 seconds."
   - Deliverable: Installed pcc binary, systemd service, configuration

4. **Backend Python Developer**: Register machine in portal
   - "Backend Python Developer: Register 'web-prod-05' in the XATbackend portal under tenant 'production'."
   - Deliverable: Machine registered, associated with tenant, API key configured

5. **Integration Architect**: Verify data flow
   - "Integration Architect: Verify that 'web-prod-05' is successfully uploading data and appearing in reports."
   - Deliverable: Validation report, troubleshooting if needed

6. **Automation Engineer**: Configure scheduled uploads
   - "Automation Engineer: Set up automated uploads from 'web-prod-05' every hour with error notification."
   - Deliverable: Systemd timer or cron job, error alerts

**Timeline**: 2-4 hours per machine (can be parallelized)

---

### Scenario 3: Implementing Upload Workflow

**Goal**: Enable perfcollector2 to upload CSV data to XATbackend

**Agent Workflow**:

1. **Integration Architect**: Design workflow
   - "Integration Architect: Design the upload workflow including file format, endpoint, authentication, and error handling."
   - Deliverable: Workflow diagram, API contract, error handling strategy

2. **Security Architect**: Design authentication
   - "Security Architect: Design Bearer token authentication for the upload endpoint with API key validation."
   - Deliverable: Auth flow, token format, key rotation strategy

3. **API Architect**: Define endpoint specification
   - "API Architect: Define the upload endpoint specification including request/response formats, error codes, and rate limits."
   - Deliverable: OpenAPI spec, endpoint documentation

4. **Go Backend Developer**: Implement upload client
   - "Go Backend Developer: Implement HTTP POST client in perfcollector2 to upload CSV files with retry logic and error handling."
   - Deliverable: Upload client code, integration with pcprocess

5. **Backend Python Developer**: Implement upload endpoint
   - "Backend Python Developer: Create Django view for /api/v1/performance/upload with CSV parsing and database storage."
   - Deliverable: Django view, URL routing, database insertion

6. **Django Tenants Specialist**: Add tenant association
   - "Django Tenants Specialist: Ensure uploaded data is correctly associated with the authenticated tenant."
   - Deliverable: Tenant-aware view, middleware configuration

7. **Data Quality Engineer**: Add upload validation
   - "Data Quality Engineer: Implement validation for uploaded CSV including column checks, data type validation, and range checks."
   - Deliverable: Validation framework, error messages, quality metrics

8. **Integration Architect**: Integration testing
   - "Integration Architect: Test end-to-end upload workflow with various scenarios including success, failure, and edge cases."
   - Deliverable: Test results, validation report, documentation

**Timeline**: 1-2 weeks

---

### Scenario 4: Generating Reports

**Goal**: Create performance analysis reports from collected data

**Agent Workflow**:

#### Option A: Direct from perfcollector2 (Development/Standalone)

1. **Go Backend Developer**: Process data to CSV
   - "Go Backend Developer: Run pcprocess to convert JSON collection to CSV format."
   - Deliverable: CSV file with standardized columns

2. **R Performance Expert**: Configure and run report
   - "R Performance Expert: Configure reporting.Rmd for the machine and generate HTML report."
   - Deliverable: HTML performance report

#### Option B: From XATbackend (Production)

1. **Backend Python Developer**: Export data from portal
   - "Backend Python Developer: Export performance data for machine 'server01' from 2026-01-01 to 2026-01-31 in CSV format."
   - Deliverable: Exported CSV file

2. **Data Quality Engineer**: Validate exported data
   - "Data Quality Engineer: Validate the exported CSV for completeness, correctness, and data quality."
   - Deliverable: Validation report, quality score

3. **R Performance Expert**: Generate report
   - "R Performance Expert: Load the exported CSV and generate comprehensive performance report with time-series analysis, percentiles, and visualizations."
   - Deliverable: HTML/PDF report with analysis

4. **Integration Architect**: Publish report to portal (future)
   - "Integration Architect: Design workflow to automatically publish generated reports back to XATbackend portal."
   - Deliverable: Upload workflow, report gallery

**Timeline**: Minutes (manual) to automated (future)

---

### Scenario 5: Troubleshooting Data Flow Issues

**Goal**: Diagnose and fix problems in the data pipeline

**Agent Workflow**:

**Symptom**: "Data is being collected but not appearing in reports"

1. **Integration Architect**: Coordinate investigation
   - "Integration Architect: Investigate why collected data is not appearing in reports. Check each stage of the pipeline."
   - Deliverable: Investigation plan, stage-by-stage checklist

2. **Go Backend Developer**: Verify collection and processing
   - "Go Backend Developer: Verify that pcc is collecting data and pcprocess is generating valid CSV files."
   - Deliverable: Collection logs, sample CSV, validation

3. **Integration Architect**: Check upload status
   - "Integration Architect: Verify that CSV files are being uploaded to XATbackend and receiving success responses."
   - Deliverable: Upload logs, HTTP responses, error analysis

4. **Backend Python Developer**: Check database storage
   - "Backend Python Developer: Query the database to confirm that uploaded data is being stored correctly."
   - Deliverable: Database query results, record counts

5. **Django Tenants Specialist**: Verify tenant association
   - "Django Tenants Specialist: Confirm that data is associated with the correct tenant and accessible to the user."
   - Deliverable: Tenant verification, access control check

6. **Data Quality Engineer**: Check data quality
   - "Data Quality Engineer: Validate that stored data meets quality requirements and has no corruption."
   - Deliverable: Quality report, anomaly detection

7. **R Performance Expert**: Verify report data source
   - "R Performance Expert: Confirm that reporting.Rmd is reading from the correct data source and processing it correctly."
   - Deliverable: Data source verification, sample data check

8. **Integration Architect**: Resolve and document
   - "Integration Architect: Based on findings from all agents, identify the root cause, implement fix, and document the issue."
   - Deliverable: Root cause analysis, fix implementation, documentation

**Timeline**: 2 hours to 2 days depending on complexity

---

## Technology Stack Deep Dive

### perfcollector2 Technology Stack

**Core Language**: Go 1.21+

**Why Go?**
- Lightweight: Small memory footprint (~10MB)
- Fast: Compiled binary, no runtime dependencies
- Concurrent: Built-in goroutines for parallel metric collection
- Cross-platform: Single binary deployment
- Static linking: No external dependencies on target system

**Standard Library Packages**:
- `net/http` - HTTP client (upload) and server (pcd)
- `encoding/json` - JSON serialization for raw collections
- `encoding/csv` - CSV export from pcprocess
- `os` - File I/O and environment variables
- `time` - Timestamp handling and intervals
- `log` - Logging framework
- `flag` - Command-line argument parsing

**Key Design Patterns**:
- **Environment variable configuration**: PCC_DURATION, PCC_FREQUENCY, PCC_MODE
- **Modular binaries**: pcc (client), pcd (server), pcprocess (processor), pcctl (admin)
- **File-based persistence**: JSON intermediate format, CSV final format
- **Trickle mode**: HTTP streaming for real-time uploads
- **API key authentication**: Simple key validation in pcd

**Data Flow**:
```go
/proc files → Go struct → JSON encoding → File or HTTP → pcprocess → CSV
```

**Building**:
```bash
make  # Builds all binaries
```

**Configuration Examples**:
```bash
# pcc: Local mode (24 hours, 15-second intervals)
PCC_DURATION=24h PCC_FREQUENCY=15s PCC_COLLECTION=~/pcc.json pcc

# pcc: Trickle mode (30 seconds, 1-second intervals)
PCC_APIKEY=8374839274 PCC_DURATION=30s PCC_FREQUENCY=1s PCC_MODE=trickle pcc

# pcd: Server on port 8080
PCD_LOGLEVEL=trace LISTENADDRESS=localhost:8080 pcd

# pcprocess: Convert JSON to CSV
PCR_COLLECTION=~/pcc.json PCR_OUTDIR=~/pcprocess.csv pcprocess
```

**Metrics Collected**:
- CPU: Per-core and aggregate from /proc/stat
- Memory: Usage from /proc/meminfo
- Disk: I/O from /proc/diskstats
- Network: Traffic from /proc/net/dev

**Relevant Agents**: Go Backend Developer, Linux Systems Engineer

---

### XATbackend Technology Stack

**Core Framework**: Django 3.2.3 (Python 3.x)

**Why Django?**
- Batteries included: ORM, admin, auth out-of-the-box
- Mature: Stable, well-documented, large ecosystem
- Multi-tenancy: django-tenants provides schema isolation
- Azure-friendly: Easy deployment to App Service
- REST-ready: Django REST Framework for APIs

**Key Dependencies**:
```
Django==3.2.3
django-tenants==3.3.1
psycopg2==2.9.x         # PostgreSQL adapter
gunicorn==20.x          # Production WSGI server
whitenoise==6.x         # Static file serving
django-cors-headers     # CORS for API
djangorestframework     # REST API framework (if used)
```

**Multi-Tenancy Architecture** (django-tenants 3.3.1):
- **Shared schema**: Tenants, public data
- **Tenant schemas**: Isolated data per tenant
- **Domain routing**: tenant1.portal.com → tenant1 schema
- **Middleware**: Automatic tenant detection from domain

**Database**: PostgreSQL 12.2
- **Why PostgreSQL?**
  - JSONB support for flexible schema
  - Excellent time-series performance
  - Schema-based multi-tenancy support
  - Azure Database for PostgreSQL integration
  - Advanced indexing (B-tree, GiST, GIN)

**Deployment**: Azure App Service
- **Platform**: Linux App Service
- **Web server**: Gunicorn (WSGI)
- **Reverse proxy**: Nginx (managed by Azure)
- **Static files**: Azure Blob Storage or WhiteNoise
- **Database**: Azure Database for PostgreSQL
- **Logging**: Azure Application Insights

**Django Apps Structure** (Expected):
```
XATbackend/
├── core/                   # Project settings
│   ├── settings.py         # Django configuration
│   ├── urls.py             # URL routing
│   └── wsgi.py             # WSGI entry point
├── apps/
│   ├── tenants/            # Tenant management
│   ├── machines/           # Machine registration
│   ├── performance/        # Performance data upload/storage
│   ├── users/              # User authentication
│   └── api/                # REST API endpoints
├── static/                 # CSS, JS, images
├── templates/              # HTML templates
├── requirements.txt        # Python dependencies
└── manage.py               # Django management command
```

**API Endpoints** (Planned):
```
POST   /api/v1/performance/upload     # Upload CSV data
GET    /api/v1/performance/export     # Export data
POST   /api/v1/machines/register      # Register machine
GET    /api/v1/machines/list          # List machines
GET    /api/v1/machines/<id>/         # Machine details
POST   /api/v1/auth/token             # Generate API token
DELETE /api/v1/auth/token             # Revoke API token
```

**Security Features**:
- Django authentication (session-based for web UI)
- API key authentication (token-based for uploads)
- CSRF protection (Django middleware)
- SQL injection prevention (ORM parameterized queries)
- XSS prevention (Django template auto-escaping)
- HTTPS enforcement (Azure configuration)
- Tenant isolation (django-tenants middleware)

**Relevant Agents**: Backend Python Developer, Django Tenants Specialist, DevOps Engineer, Security Architect

---

### automated-Reporting Technology Stack

**Core Language**: R 4.5.2+

**Why R?**
- Statistical analysis: Built for data analysis
- Visualization: ggplot2 is best-in-class
- R Markdown: Literate programming for reports
- Packages: 19,000+ CRAN packages
- Reproducibility: renv for environment management
- PDF/HTML: Easy report generation

**Core Packages**:
```r
ggplot2 (>= 3.4.0)      # Data visualization
dplyr (>= 1.1.0)        # Data manipulation
lubridate (>= 1.9.0)    # Date/time handling
fmsb (>= 0.7.6)         # Radar charts
knitr (>= 1.45)         # Report knitting
rmarkdown (>= 2.20)     # Report rendering
```

**Performance Packages** (Recommended):
```r
data.table (>= 1.14.0)  # High-performance data manipulation (10-100x faster)
profvis (>= 0.3.0)      # Code profiling
Rcpp (>= 1.0.0)         # C++ integration for speed
```

**Future Packages** (Oracle Integration):
```r
ROracle (>= 1.3.0)      # Oracle database connector
DBI (>= 1.1.0)          # Database interface
odbc (>= 1.3.0)         # Alternative Oracle connector
yaml (>= 2.3.0)         # YAML configuration
assertr (>= 3.0.0)      # Data validation
```

**Report Structure** (reporting.Rmd - 2,039 lines):

1. **Setup Section** (Lines 1-50):
   - Library loading
   - Configuration (NEEDS YAML REPLACEMENT)
   - Helper functions
   - Theme definitions

2. **Data Loading** (Lines 51-200):
   - Read /proc/stat (CPU)
   - Read /proc/meminfo (Memory)
   - Read /proc/diskstats (Disk)
   - Read /proc/net/dev (Network)
   - Timestamp parsing and alignment

3. **Data Processing** (Lines 201-500):
   - CPU calculations (percentages, per-core)
   - Memory calculations (used, available, buffers, cache)
   - Disk calculations (IOPS, throughput)
   - Network calculations (Mbps, packet rate)
   - Percentile calculations (95th, 97.5th, 99th, 100th)

4. **Visualizations** (Lines 501-1500):
   - Time-series line charts (ggplot2)
   - Faceted charts (per-CPU, per-device)
   - Radar charts (fmsb)
   - Summary tables (knitr::kable)
   - Custom themes and colors

5. **Summary Section** (Lines 1501-2039):
   - Executive summary
   - Key metrics
   - Recommendations
   - Machine metadata
   - Report generation timestamp

**Hardcoded Configuration** (CRITICAL ISSUE):
```r
# Lines 24-30 in reporting.Rmd
storeVol <- "sda"              # MUST MATCH ACTUAL DISK
netIface <- "ens33"            # MUST MATCH ACTUAL INTERFACE
machName <- "machine001"       # MUST BE UNIQUE
UUID <- "0001-001-002"         # MUST BE UNIQUE
loc <- ("testData/proc/")      # MUST EXIST
```

**Planned Replacement** (YAML Configuration):
```yaml
# config/machine.yaml
machine:
  name: "machine001"
  uuid: "0001-001-002"
  storage_device: "sda"     # Or auto-detect
  network_interface: "ens33" # Or auto-detect
  data_location: "testData/proc/"
```

**Report Generation**:
```bash
# HTML output (recommended)
Rscript -e "rmarkdown::render('reporting.Rmd', output_format='html_document')"

# PDF output (requires LaTeX)
Rscript -e "rmarkdown::render('reporting.Rmd', output_format='pdf_document')"

# Both formats
Rscript -e "rmarkdown::render('reporting.Rmd', output_format='all')"
```

**Performance Optimization Opportunities**:
- Replace data.frame with data.table (10-100x speedup)
- Vectorize loops (if any remain)
- Pre-allocate vectors
- Cache expensive computations
- Use profvis to identify bottlenecks

**Relevant Agents**: R Performance Expert, Data Architect, Configuration Management Specialist, Automation Engineer

---

## File Structure Reference

```
/Users/danmcdougal/projects/PerfAnalysis/
│
├── claude.md                          # THIS FILE - Project guide for Claude Code
├── .gitmodules                        # Git submodule configuration
│
├── agents/                            # 16 specialized AI agents
│   ├── 00-AGENT_DIRECTORY.md          # Quick reference index
│   ├── AGENT_MANIFEST.yaml            # Detailed manifest with routing rules
│   ├── README.md                      # Agent overview and usage guide
│   │
│   ├── backend/                       # Backend development agents (3)
│   │   ├── go-backend-developer.md
│   │   ├── backend-python-developer.md
│   │   └── django-tenants-specialist.md
│   │
│   ├── operational/                   # Operational agents (4)
│   │   ├── linux-systems-engineer.md
│   │   ├── automation-engineer.md
│   │   ├── configuration-management-specialist.md
│   │   └── data-quality-engineer.md
│   │
│   ├── performance/                   # Performance agent (1)
│   │   └── r-performance-expert.md
│   │
│   ├── database/                      # Database agents (3)
│   │   ├── data-architect.md
│   │   ├── time-series-architect.md
│   │   └── agent-oracle-developer.md
│   │
│   ├── integration/                   # Integration agent (1)
│   │   └── integration-architect.md
│   │
│   └── architecture/                  # Architecture agents (4)
│       ├── api-architect.md
│       ├── security-architect.md
│       ├── solutions-architect-sais.md
│       └── devops-engineer.md
│
├── perfcollector2/                    # Go-based data collection (SUBMODULE)
│   ├── README.md                      # Component documentation
│   ├── Makefile                       # Build configuration
│   ├── go.mod                         # Go module definition
│   ├── go.sum                         # Go dependency checksums
│   │
│   ├── cmd/                           # Executable commands
│   │   ├── pcc/                       # Client: data collector
│   │   ├── pcd/                       # Daemon: data receiver
│   │   ├── pcprocess/                 # Processor: JSON to CSV
│   │   └── pcctl/                     # Controller: admin tool
│   │
│   ├── internal/                      # Internal packages
│   │   ├── collector/                 # Metric collection logic
│   │   ├── parser/                    # /proc file parsing
│   │   └── uploader/                  # HTTP upload client
│   │
│   └── bin/                           # Compiled binaries (git-ignored)
│       ├── pcc
│       ├── pcd
│       ├── pcprocess
│       └── pcctl
│
├── XATbackend/                        # Django multi-tenant portal (SUBMODULE)
│   ├── README.md                      # Component documentation
│   ├── requirements.txt               # Python dependencies
│   ├── manage.py                      # Django management commands
│   │
│   ├── core/                          # Project configuration
│   │   ├── settings.py                # Django settings
│   │   ├── urls.py                    # URL routing
│   │   └── wsgi.py                    # WSGI entry point
│   │
│   ├── apps/                          # Django applications
│   │   ├── tenants/                   # Tenant management
│   │   ├── machines/                  # Machine registry
│   │   ├── performance/               # Performance data
│   │   ├── users/                     # User auth
│   │   └── api/                       # REST API
│   │
│   ├── static/                        # Static files (CSS, JS, images)
│   ├── templates/                     # HTML templates
│   │
│   ├── .azure/                        # Azure deployment config
│   ├── Dockerfile                     # Container definition
│   └── docker-compose.yml             # Local development stack
│
├── automated-Reporting/               # R-based visualization (SUBMODULE)
│   ├── claude.md                      # Component-specific guide (669 lines)
│   ├── README.md                      # User documentation
│   ├── ORACLE_INTEGRATION_GUIDE.md    # Oracle migration roadmap
│   ├── QUICKSTART_ORACLE.md           # 30-minute Oracle setup
│   │
│   ├── reporting.Rmd                  # Main report template (2,039 lines)
│   ├── DESCRIPTION                    # R package dependencies
│   ├── renv_init.R                    # Environment setup
│   ├── .gitignore                     # R artifacts
│   │
│   ├── testData/                      # Sample data
│   │   └── proc/                      # Linux /proc format
│   │       ├── stat                   # CPU metrics
│   │       ├── meminfo                # Memory metrics
│   │       ├── diskstats              # Disk I/O metrics
│   │       └── net/dev                # Network metrics
│   │
│   ├── agents/                        # 21 agents (superset of parent)
│   │   ├── 00-agent-directory.md
│   │   ├── agent-manifest.md
│   │   └── ... (all agents)
│   │
│   ├── config/                        # Configuration (Phase 2)
│   │   └── oracle/
│   │       ├── connection.yaml
│   │       └── credentials.template
│   │
│   ├── db/                            # Database artifacts (Phase 2)
│   │   └── oracle/
│   │       ├── schema/                # DDL scripts
│   │       ├── migrations/            # Schema versioning
│   │       └── queries/               # SQL queries
│   │
│   ├── R/                             # R modules (Phase 2)
│   │   └── database/
│   │       ├── oracle_connection.R
│   │       ├── data_loader.R
│   │       └── query_builder.R
│   │
│   └── docs/                          # Documentation (Phase 2)
│       └── oracle/
│           ├── SETUP.md
│           ├── SCHEMA_DESIGN.md
│           ├── API_DESIGN.md
│           └── SECURITY.md
│
└── claude-agents/                     # Centralized agent repository (SUBMODULE)
    ├── README.md                      # Agent collection overview
    ├── scripts/                       # Agent sync scripts
    └── agents/                        # Shared agent definitions
        └── ... (all agents, synced to parent and children)
```

---

## Development Workflows

### Workflow 1: perfcollector2 Development

**Scenario**: Implementing new metric collection

**Steps**:

1. **Identify Metric** (Linux Systems Engineer):
   ```
   "As the Linux Systems Engineer, what metrics are available in /proc/vmstat
   and which ones are most useful for memory performance analysis?"
   ```

2. **Design Implementation** (Go Backend Developer):
   ```
   "As the Go Backend Developer, design the Go struct and parsing logic for
   /proc/vmstat metrics identified by the Linux Systems Engineer."
   ```

3. **Implement Parsing** (Go Backend Developer):
   ```r
   // File: internal/parser/vmstat.go
   package parser

   import (
       "bufio"
       "os"
       "strconv"
       "strings"
   )

   type VMStat struct {
       NrFreePages     int64
       NrInactiveAnon  int64
       NrActiveAnon    int64
       Pgpgin          int64
       Pgpgout         int64
       // ... more fields
   }

   func ParseVMStat(path string) (*VMStat, error) {
       file, err := os.Open(path)
       if err != nil {
           return nil, err
       }
       defer file.Close()

       vmstat := &VMStat{}
       scanner := bufio.NewScanner(file)

       for scanner.Scan() {
           fields := strings.Fields(scanner.Text())
           if len(fields) < 2 {
               continue
           }

           value, err := strconv.ParseInt(fields[1], 10, 64)
           if err != nil {
               continue
           }

           switch fields[0] {
           case "nr_free_pages":
               vmstat.NrFreePages = value
           case "nr_inactive_anon":
               vmstat.NrInactiveAnon = value
           // ... more cases
           }
       }

       return vmstat, scanner.Err()
   }
   ```

4. **Integrate into pcc** (Go Backend Developer):
   ```
   "As the Go Backend Developer, integrate vmstat parsing into pcc's
   collection loop and add to JSON output."
   ```

5. **Update pcprocess** (Go Backend Developer):
   ```
   "As the Go Backend Developer, update pcprocess to include vmstat metrics
   in the CSV output with standardized column names."
   ```

6. **Add Validation** (Data Quality Engineer):
   ```
   "As the Data Quality Engineer, add validation rules for vmstat metrics
   including range checks and anomaly detection."
   ```

7. **Test** (Go Backend Developer + Linux Systems Engineer):
   ```bash
   # Build
   make

   # Test collection
   PCC_DURATION=1m PCC_FREQUENCY=1s PCC_COLLECTION=test.json ./bin/pcc

   # Test processing
   PCR_COLLECTION=test.json PCR_OUTDIR=test.csv ./bin/pcprocess

   # Verify CSV
   head test.csv
   ```

8. **Document** (Go Backend Developer):
   ```
   Update README.md with vmstat metrics, column names, and usage examples.
   ```

**Relevant Agents**: Go Backend Developer, Linux Systems Engineer, Data Quality Engineer

---

### Workflow 2: XATbackend Development

**Scenario**: Implementing upload API endpoint

**Steps**:

1. **Design API** (API Architect + Integration Architect):
   ```
   "API Architect and Integration Architect: Design the upload API endpoint
   specification including request format, response format, error codes,
   and rate limits."
   ```

2. **Design Security** (Security Architect):
   ```
   "As the Security Architect, design Bearer token authentication for the
   upload endpoint with API key generation, validation, and rotation."
   ```

3. **Design Multi-Tenancy** (Django Tenants Specialist):
   ```
   "As the Django Tenants Specialist, ensure uploaded data is correctly
   associated with the authenticated tenant and stored in the tenant schema."
   ```

4. **Implement View** (Backend Python Developer):
   ```python
   # File: apps/performance/views.py
   from django.views.decorators.csrf import csrf_exempt
   from django.http import JsonResponse
   from django.views.decorators.http import require_POST
   import csv
   import io
   from .models import PerformanceData
   from .authentication import validate_api_key
   from .validators import validate_csv_format

   @csrf_exempt  # API uses Bearer token, not CSRF
   @require_POST
   def upload_performance_data(request):
       # Authenticate
       api_key = request.META.get('HTTP_AUTHORIZATION', '').replace('Bearer ', '')
       user, machine = validate_api_key(api_key)
       if not user:
           return JsonResponse({
               'status': 'error',
               'error_code': 'INVALID_API_KEY',
               'message': 'Invalid or missing API key'
           }, status=401)

       # Get uploaded file
       uploaded_file = request.FILES.get('file')
       if not uploaded_file:
           return JsonResponse({
               'status': 'error',
               'error_code': 'MISSING_FILE',
               'message': 'No file provided'
           }, status=400)

       # Validate CSV format
       try:
           csv_content = uploaded_file.read().decode('utf-8')
           validation_result = validate_csv_format(csv_content)
           if not validation_result['valid']:
               return JsonResponse({
                   'status': 'error',
                   'error_code': 'INVALID_CSV_FORMAT',
                   'message': validation_result['message'],
                   'details': validation_result['details']
               }, status=400)
       except Exception as e:
           return JsonResponse({
               'status': 'error',
               'error_code': 'FILE_READ_ERROR',
               'message': str(e)
           }, status=400)

       # Parse and store CSV
       csv_file = io.StringIO(csv_content)
       reader = csv.DictReader(csv_file)
       records_processed = 0

       for row in reader:
           PerformanceData.objects.create(
               machine=machine,
               tenant=user.tenant,
               timestamp=row['timestamp'],
               cpu_user=row['cpu_user'],
               cpu_system=row['cpu_system'],
               # ... more fields
           )
           records_processed += 1

       return JsonResponse({
           'status': 'success',
           'message': 'Performance data uploaded successfully',
           'records_processed': records_processed,
           'machine_id': machine.id,
           'tenant_id': user.tenant.id
       }, status=201)
   ```

5. **Implement Authentication** (Security Architect + Backend Python Developer):
   ```python
   # File: apps/performance/authentication.py
   from apps.machines.models import Machine, APIKey
   from django.contrib.auth import get_user_model
   import hashlib

   User = get_user_model()

   def validate_api_key(key):
       """Validate API key and return (user, machine) or (None, None)"""
       if not key or len(key) < 8:
           return None, None

       # Hash the key (keys are stored hashed)
       key_hash = hashlib.sha256(key.encode()).hexdigest()

       try:
           api_key_obj = APIKey.objects.get(
               key_hash=key_hash,
               is_active=True
           )

           # Check expiration
           if api_key_obj.is_expired():
               return None, None

           return api_key_obj.user, api_key_obj.machine
       except APIKey.DoesNotExist:
           return None, None
   ```

6. **Add Validation** (Data Quality Engineer):
   ```python
   # File: apps/performance/validators.py
   import csv
   import io

   REQUIRED_COLUMNS = [
       'timestamp', 'machine_id', 'cpu_user', 'cpu_system', 'cpu_idle',
       'mem_total', 'mem_used', 'mem_available',
       'disk_read_bytes', 'disk_write_bytes',
       'net_rx_bytes', 'net_tx_bytes'
   ]

   def validate_csv_format(csv_content):
       """Validate CSV format and return validation result"""
       try:
           csv_file = io.StringIO(csv_content)
           reader = csv.DictReader(csv_file)

           # Check columns
           found_columns = set(reader.fieldnames)
           missing_columns = set(REQUIRED_COLUMNS) - found_columns

           if missing_columns:
               return {
                   'valid': False,
                   'message': f'Missing required columns: {", ".join(missing_columns)}',
                   'details': {
                       'found_columns': list(found_columns),
                       'missing_columns': list(missing_columns)
                   }
               }

           # Validate data (sample first 10 rows)
           for i, row in enumerate(reader):
               if i >= 10:
                   break

               # Validate CPU percentages (0-100)
               for col in ['cpu_user', 'cpu_system', 'cpu_idle']:
                   try:
                       value = float(row[col])
                       if value < 0 or value > 100:
                           return {
                               'valid': False,
                               'message': f'{col} must be between 0 and 100',
                               'details': {'row': i+1, 'column': col, 'value': value}
                           }
                   except ValueError:
                       return {
                           'valid': False,
                           'message': f'{col} must be numeric',
                           'details': {'row': i+1, 'column': col}
                       }

           return {'valid': True, 'message': 'CSV format valid'}

       except Exception as e:
           return {
               'valid': False,
               'message': f'CSV parsing error: {str(e)}',
               'details': {}
           }
   ```

7. **Add URL Routing** (Backend Python Developer):
   ```python
   # File: core/urls.py
   from django.urls import path
   from apps.performance import views

   urlpatterns = [
       # ... existing patterns
       path('api/v1/performance/upload', views.upload_performance_data, name='upload_performance'),
   ]
   ```

8. **Test** (Integration Architect):
   ```bash
   # Test with curl
   curl -X POST \
        -H "Authorization: Bearer YOUR_API_KEY_HERE" \
        -F "file=@test_data.csv" \
        http://localhost:8000/api/v1/performance/upload

   # Test with Python
   python manage.py test apps.performance.tests.test_upload
   ```

**Relevant Agents**: Backend Python Developer, Django Tenants Specialist, Security Architect, API Architect, Integration Architect, Data Quality Engineer

---

### Workflow 3: automated-Reporting Development

**Scenario**: Optimizing slow report generation

**Steps**:

1. **Profile Code** (R Performance Expert):
   ```r
   # Install profvis if not already installed
   install.packages("profvis")

   # Profile the report
   library(profvis)
   profvis({
       rmarkdown::render("reporting.Rmd", output_format = "html_document")
   })

   # This will open an interactive profiling visualization
   # Look for functions taking the most time
   ```

2. **Identify Bottlenecks** (R Performance Expert):
   ```
   "As the R Performance Expert, based on the profvis output, identify the
   top 3 bottlenecks in reporting.Rmd and recommend optimization strategies."
   ```

   Typical findings:
   - data.frame operations on large datasets → use data.table
   - Loops over rows → vectorize
   - Repeated file I/O → cache data
   - Large object copies → use in-place modification

3. **Optimize Data Loading** (R Performance Expert):
   ```r
   # BEFORE (slow)
   cpu_data <- read.csv("data/cpu.csv", stringsAsFactors = FALSE)

   # AFTER (faster with data.table)
   library(data.table)
   cpu_data <- fread("data/cpu.csv")
   ```

4. **Optimize Data Manipulation** (R Performance Expert):
   ```r
   # BEFORE (slow - data.frame)
   library(dplyr)
   cpu_summary <- cpu_data %>%
       group_by(timestamp) %>%
       summarise(
           avg_user = mean(cpu_user),
           avg_system = mean(cpu_system),
           avg_idle = mean(cpu_idle)
       )

   # AFTER (fast - data.table)
   library(data.table)
   setDT(cpu_data)  # Convert to data.table in-place
   cpu_summary <- cpu_data[, .(
       avg_user = mean(cpu_user),
       avg_system = mean(cpu_system),
       avg_idle = mean(cpu_idle)
   ), by = timestamp]

   # Speedup: 10-100x for large datasets
   ```

5. **Optimize Loops** (R Performance Expert):
   ```r
   # BEFORE (slow - loop)
   cpu_pct <- numeric(nrow(cpu_data))
   for (i in 1:nrow(cpu_data)) {
       cpu_pct[i] <- 100 - cpu_data$cpu_idle[i]
   }

   # AFTER (fast - vectorized)
   cpu_pct <- 100 - cpu_data$cpu_idle

   # Speedup: 100-1000x
   ```

6. **Optimize Visualization** (R Performance Expert):
   ```r
   # For very large datasets, downsample before plotting
   # BEFORE (slow - plot all 86400 points for 24h at 1s intervals)
   ggplot(cpu_data, aes(x = timestamp, y = cpu_user)) +
       geom_line()

   # AFTER (fast - downsample to 1000 points)
   library(dplyr)
   cpu_data_sampled <- cpu_data %>%
       mutate(group = ntile(row_number(), 1000)) %>%
       group_by(group) %>%
       summarise(
           timestamp = mean(timestamp),
           cpu_user = mean(cpu_user)
       )

   ggplot(cpu_data_sampled, aes(x = timestamp, y = cpu_user)) +
       geom_line()

   # Speedup: 10-50x rendering time
   ```

7. **Cache Expensive Computations** (R Performance Expert):
   ```r
   # Use R Markdown caching for expensive chunks
   ```{r load-data, cache=TRUE}
   # This chunk will only run if code changes
   cpu_data <- fread("data/cpu.csv")
   mem_data <- fread("data/mem.csv")
   ```

   ```{r process-data, cache=TRUE, dependson="load-data"}
   # This chunk depends on load-data
   # Will only re-run if load-data changes
   cpu_summary <- cpu_data[, .(avg = mean(cpu_user)), by = timestamp]
   ```
   ```

8. **Benchmark Improvements** (R Performance Expert):
   ```r
   library(microbenchmark)

   # Compare old vs new approach
   microbenchmark(
       old = {
           # old code
       },
       new = {
           # new code
       },
       times = 10
   )
   ```

9. **Document Optimizations** (R Performance Expert):
   ```
   Add comments in reporting.Rmd explaining optimizations and expected
   performance characteristics.
   ```

**Relevant Agents**: R Performance Expert, Data Architect

---

### Workflow 4: Integration Testing

**Scenario**: Testing end-to-end data flow

**Steps**:

1. **Plan Testing** (Integration Architect):
   ```
   "As the Integration Architect, create a comprehensive test plan for the
   end-to-end data flow from pcc collection through XATbackend storage to
   automated-Reporting visualization."
   ```

2. **Stage 1: Collection Test** (Go Backend Developer):
   ```bash
   # Test pcc collection
   PCC_DURATION=5m PCC_FREQUENCY=1s PCC_COLLECTION=test.json ./bin/pcc

   # Verify JSON output
   cat test.json | jq '.samples | length'  # Should show ~300 samples
   ```

3. **Stage 2: Processing Test** (Go Backend Developer):
   ```bash
   # Test pcprocess conversion
   PCR_COLLECTION=test.json PCR_OUTDIR=test.csv ./bin/pcprocess

   # Verify CSV output
   wc -l test.csv  # Should show ~300 rows + header
   head test.csv   # Verify column names
   ```

4. **Stage 3: Upload Test** (Integration Architect + Go Backend Developer):
   ```bash
   # Test upload to XATbackend
   curl -X POST \
        -H "Authorization: Bearer TEST_API_KEY" \
        -F "file=@test.csv" \
        -F "machine_id=test-machine-01" \
        http://localhost:8000/api/v1/performance/upload

   # Verify response
   # Expected: {"status": "success", "records_processed": 300, ...}
   ```

5. **Stage 4: Storage Verification** (Backend Python Developer):
   ```python
   # Django shell
   python manage.py shell

   from apps.performance.models import PerformanceData

   # Count records
   count = PerformanceData.objects.filter(
       machine__machine_id='test-machine-01'
   ).count()
   print(f"Stored records: {count}")  # Should be 300

   # Verify data
   sample = PerformanceData.objects.filter(
       machine__machine_id='test-machine-01'
   ).first()
   print(f"Sample: {sample.cpu_user}, {sample.mem_used}")
   ```

6. **Stage 5: Export Test** (Backend Python Developer):
   ```bash
   # Export data for reporting
   curl -X GET \
        -H "Authorization: Bearer USER_API_KEY" \
        "http://localhost:8000/api/v1/performance/export?machine_id=test-machine-01" \
        > exported.csv

   # Verify export
   wc -l exported.csv  # Should show ~300 rows + header
   ```

7. **Stage 6: Report Generation Test** (R Performance Expert):
   ```r
   # Update reporting.Rmd configuration
   # Set loc <- "path/to/exported.csv"

   # Generate report
   rmarkdown::render("reporting.Rmd", output_format = "html_document")

   # Verify report exists
   file.exists("reporting.html")  # Should be TRUE
   ```

8. **Stage 7: Visual Verification** (Integration Architect):
   ```
   Open reporting.html in browser and verify:
   - Time-series charts display correctly
   - Metrics match expected values
   - No errors or warnings in report
   - All sections render properly
   ```

9. **Document Results** (Integration Architect):
   ```
   Create test report documenting:
   - Test scenarios executed
   - Results (pass/fail)
   - Issues identified
   - Performance metrics (time, data size)
   - Recommendations for improvements
   ```

**Relevant Agents**: Integration Architect, Go Backend Developer, Backend Python Developer, R Performance Expert

---

## Best Practices

### 1. Always Start with Agent Selection

**THE RULE**: Before doing anything, identify the appropriate agent(s).

**Why**: Each agent has specialized knowledge that generic responses lack.

**Examples**:

```
❌ WRONG:
User: "How do I add a new metric?"
Claude: "You need to modify the code to collect the metric..."

✅ CORRECT:
User: "How do I add a new metric to perfcollector2?"
Claude: "I'll coordinate this across multiple agents:

Linux Systems Engineer: Identify available /proc metrics
Go Backend Developer: Implement parsing and collection
Data Quality Engineer: Add validation rules
Integration Architect: Ensure proper data flow

Starting with the Linux Systems Engineer..."
```

---

### 2. Use Integration Architect for Cross-System Questions

**THE RULE**: When a task involves multiple components, start with the Integration Architect.

**Why**: They understand the entire system and can coordinate other agents.

**Examples**:

```
✅ CORRECT:
"Integration Architect: I need to implement the workflow for uploading
performance data from perfcollector2 to XATbackend. What agents do I need
and what is the proper sequence?"

The Integration Architect will respond:
"This requires coordination of 5 agents in this sequence:
1. Security Architect - Design authentication
2. API Architect - Define endpoint specification
3. Go Backend Developer - Implement upload client
4. Backend Python Developer - Implement upload endpoint
5. Data Quality Engineer - Add validation

Let's start with the Security Architect..."
```

---

### 3. Consult Component-Specific Agents for Implementation

**THE RULE**: For implementation details, use the agent specialized in that technology.

**Why**: Component agents have deep technical knowledge and code examples.

**Examples**:

```
✅ FOR GO CODE:
"As the Go Backend Developer, implement HTTP retry logic with exponential
backoff for the upload client."

✅ FOR DJANGO CODE:
"As the Backend Python Developer, create a Django view for the upload
endpoint with proper error handling."

✅ FOR R CODE:
"As the R Performance Expert, convert this dplyr code to data.table for
better performance."
```

---

### 4. Leverage Multi-Agent Collaboration for Complex Tasks

**THE RULE**: Don't try to solve complex problems with a single agent.

**Why**: Complex tasks require multiple perspectives and expertise areas.

**Examples**:

```
✅ COMPLEX TASK - SECURITY:
"Security Architect and Django Tenants Specialist: Design the authentication
and authorization system for the multi-tenant upload API ensuring tenant
isolation and API key security."

✅ COMPLEX TASK - PERFORMANCE:
"R Performance Expert and Data Architect: Optimize the report generation
for 1 million rows of performance data, considering both R code optimization
and database pre-aggregation."

✅ COMPLEX TASK - DEPLOYMENT:
"DevOps Engineer, Solutions Architect, and Security Architect: Design the
Azure deployment architecture for XATbackend with high availability,
disaster recovery, and security best practices."
```

---

### 5. Provide Context and Constraints

**THE RULE**: When requesting help, include relevant context and constraints.

**Why**: Agents can provide better, more specific advice with context.

**Examples**:

```
❌ INSUFFICIENT CONTEXT:
"Optimize this R code."

✅ SUFFICIENT CONTEXT:
"As the R Performance Expert: This R code processes 100K rows of CPU metrics
with 10 numeric columns. It currently takes 30 seconds using data.frame and
dplyr. The code groups by timestamp and calculates mean, median, and
percentiles. How can I optimize this to run in under 5 seconds?"
```

---

### 6. Request Specific Deliverables

**THE RULE**: Be explicit about what you want as output.

**Why**: Clear deliverables ensure you get actionable results.

**Examples**:

```
❌ VAGUE:
"Think about database schema."

✅ SPECIFIC:
"As the Data Architect: Design the PostgreSQL schema for storing performance
metrics with 1-second granularity and 30-day retention. Provide:
1. DDL scripts for tables and indexes
2. Partitioning strategy
3. Query optimization recommendations
4. Storage size estimates"
```

---

### 7. Follow Technology-Specific Best Practices

**THE RULE**: Each technology has its own best practices. Use the appropriate agent to ensure compliance.

**Technology-Specific Guidance**:

#### Go (perfcollector2)
- **Agent**: Go Backend Developer
- **Best Practices**:
  - Use environment variables for configuration
  - Implement proper error handling (not panic)
  - Close resources with defer
  - Use goroutines for concurrent collection
  - Static compilation for deployment

#### Django (XATbackend)
- **Agent**: Backend Python Developer, Django Tenants Specialist
- **Best Practices**:
  - Use Django ORM (avoid raw SQL)
  - Implement proper middleware
  - Use django-tenants for multi-tenancy
  - Validate all inputs
  - Use Django's security features (CSRF, XSS protection)

#### R (automated-Reporting)
- **Agent**: R Performance Expert
- **Best Practices**:
  - Use data.table for large datasets
  - Vectorize operations (avoid loops)
  - Cache expensive R Markdown chunks
  - Pre-allocate vectors
  - Profile with profvis before optimizing

---

### 8. Security First

**THE RULE**: For any feature involving data transfer, authentication, or multi-tenancy, consult the Security Architect first.

**Why**: Security issues are expensive to fix after implementation.

**Security Checklist**:
- ✅ API authentication (Security Architect)
- ✅ Input validation (Data Quality Engineer + Security Architect)
- ✅ SQL injection prevention (Backend Python Developer + Security Architect)
- ✅ Tenant isolation (Django Tenants Specialist + Security Architect)
- ✅ HTTPS enforcement (DevOps Engineer + Security Architect)
- ✅ API key rotation (Security Architect)

---

### 9. Test Integration Points

**THE RULE**: Always test the boundaries between components.

**Why**: Integration failures are the most common source of production issues.

**Testing Approach**:

```
"Integration Architect: Create a test plan for the upload workflow covering:
1. Go upload client success
2. Go upload client failure (network, auth, validation)
3. Django upload endpoint success
4. Django upload endpoint failure (invalid CSV, auth, tenant)
5. Database storage and retrieval
6. CSV export for reporting
7. R report generation from exported data

Include expected inputs, outputs, and error messages for each scenario."
```

---

### 10. Document Decisions and Rationale

**THE RULE**: Document why you made specific design decisions.

**Why**: Future developers (including future you) need to understand the reasoning.

**Documentation Approach**:

```
"Configuration Management Specialist: Create configuration documentation
explaining:
- Why we chose YAML over JSON
- What each configuration parameter controls
- Default values and their rationale
- How to override defaults
- Security considerations for each parameter
- Examples of common configurations"
```

---

## CRITICAL DEBUGGING PROTOCOLS

These protocols are **MANDATORY** for all agents when debugging web application issues. Failure to follow these protocols has historically resulted in repeated failed fixes and wasted user time.

### Protocol 1: Django Template Inheritance Audit

**WHEN**: Any `NoReverseMatch`, `TemplateSyntaxError`, or template-related Django error

**THE RULE**: When a template error occurs, search ALL templates for the same pattern before making any fix.

**MANDATORY STEPS**:
1. Identify the error pattern (e.g., `{% url 'dashboard:...' %}`)
2. Run codebase-wide search BEFORE any edits:
   ```bash
   grep -r "{% url 'NAMESPACE:" --include="*.html" XATbackend/
   ```
3. List ALL files containing the pattern
4. Fix ALL occurrences in a single pass
5. Never claim a fix is complete until all instances are addressed

**WHY**: Django templates extend (`{% extends %}`) and include (`{% include %}`) other templates. A fix in one template is NEVER complete without auditing the entire template tree.

**EXAMPLE**:
```
❌ WRONG: Fix only the file mentioned in the traceback
✅ CORRECT: Search entire codebase, list all affected files, fix all at once
```

---

### Protocol 2: Browser Verification Requirement

**WHEN**: Any web UI fix, template change, or frontend modification

**THE RULE**: HTTP 200 response ≠ working page. A fix is NOT verified until actual browser rendering is confirmed.

**MANDATORY STEPS**:
1. After making changes, do NOT rely solely on HTTP status codes
2. HTTP 200 means Django returned *something*, not that it rendered correctly
3. Verify fix by one of:
   - User confirmation that page works
   - Browser developer tools console check (no errors)
   - Actual page content inspection
4. Never claim "fix successful" based only on server logs showing 200

**WHY**: Django can return HTTP 200 with an error page, partial render, or template exception displayed to the user.

**EXAMPLE**:
```
❌ WRONG: "Docker logs show 200 6885, fix is successful"
✅ CORRECT: "Please verify the page loads correctly in your browser"
```

---

### Protocol 3: Atomic Fix Completion

**WHEN**: Fixing any pattern-based issue in code or templates

**THE RULE**: When fixing a pattern in a file, fix ALL instances in that file before moving to the next step.

**MANDATORY STEPS**:
1. After identifying a pattern to fix in a file, count all instances
2. Use search within the file to find every occurrence
3. Fix ALL instances in that file in one editing session
4. Never leave a file in a partially-fixed state
5. Verify the count of fixes matches the count of occurrences

**WHY**: Partial fixes create confusing states where some functionality works and some doesn't, making debugging harder.

**EXAMPLE**:
```
❌ WRONG: Fix one URL in home.html, move on, fix another when error appears
✅ CORRECT: Search home.html for all {% url 'dashboard:' %}, fix all 5 at once
```

---

### Protocol 4: Pattern-Based Bug Hunting

**WHEN**: Any bug caused by a repeated pattern (URL namespaces, import statements, configuration values, etc.)

**THE RULE**: When a bug is caused by a pattern, the FIRST action must be a codebase-wide search. Define fix scope BEFORE any edits.

**MANDATORY STEPS**:
1. Identify the problematic pattern from the error
2. IMMEDIATELY run codebase-wide search:
   ```bash
   grep -r "PATTERN" --include="*.EXT" .
   ```
3. Document ALL files and line counts that need changes
4. Create a fix plan listing every change needed
5. Execute fixes systematically
6. Verify each file is fully fixed before moving to next

**WHY**: Reactive fixing (fix one, wait for error, fix next) wastes time and frustrates users. Proactive pattern hunting solves the entire problem class at once.

**EXAMPLE**:
```
❌ WRONG:
  Error in sidenav.html → fix sidenav.html
  Error persists → check home.html → fix home.html
  Error persists → check base.html → fix base.html

✅ CORRECT:
  Error mentions {% url 'dashboard:' %}
  → grep -r "{% url 'dashboard:" --include="*.html" .
  → Found in: sidenav.html (1), home.html (5), base.html (2)
  → Fix all 8 occurrences across 3 files
  → Verify with user
```

---

### Protocol Summary Table

| Protocol | Trigger | First Action | Verification |
|----------|---------|--------------|--------------|
| Template Audit | Template error | `grep -r` all templates | All files listed and fixed |
| Browser Verify | Any UI fix | Request browser check | User confirms page works |
| Atomic Fix | Pattern in file | Count all instances | Fix count = instance count |
| Pattern Hunt | Pattern-based bug | Codebase-wide search | All files fixed in one pass |

---

## Troubleshooting Guide

### Problem: "Data is collected but not in the database"

**Symptoms**:
- pcc runs successfully
- pcprocess generates CSV
- Upload returns 200 OK
- Database queries return no records

**Troubleshooting Workflow**:

1. **Integration Architect**: Coordinate investigation
   ```
   "Integration Architect: Investigate missing data in database. Check each
   stage of the pipeline: collection, processing, upload, storage."
   ```

2. **Go Backend Developer**: Verify CSV format
   ```
   "Go Backend Developer: Verify the CSV generated by pcprocess matches the
   expected format. Check column names and data types."
   ```

3. **Backend Python Developer**: Check upload endpoint
   ```
   "Backend Python Developer: Add debug logging to the upload endpoint.
   Verify the CSV is being parsed correctly and database insert is called."
   ```

4. **Django Tenants Specialist**: Verify tenant context
   ```
   "Django Tenants Specialist: Confirm the upload is associated with the
   correct tenant and data is being written to the tenant schema."
   ```

5. **Security Architect**: Verify authentication
   ```
   "Security Architect: Confirm the API key is valid and has proper
   permissions for the target machine and tenant."
   ```

6. **Data Quality Engineer**: Check validation
   ```
   "Data Quality Engineer: Verify the uploaded data passes all validation
   rules and isn't being rejected silently."
   ```

**Common Causes**:
- ❌ Wrong tenant schema (django-tenants issue)
- ❌ API key lacks permissions
- ❌ CSV format mismatch
- ❌ Validation silently failing
- ❌ Database connection issue
- ❌ Transaction not committing

---

### Problem: "R report generation is very slow"

**Symptoms**:
- reporting.Rmd takes 5+ minutes
- High CPU usage during rendering
- Large memory consumption

**Troubleshooting Workflow**:

1. **R Performance Expert**: Profile the code
   ```r
   library(profvis)
   profvis({
       rmarkdown::render("reporting.Rmd")
   })
   ```

2. **R Performance Expert**: Identify bottlenecks
   ```
   "As the R Performance Expert, based on the profvis output, what are the
   top 3 performance bottlenecks and what optimization strategies do you
   recommend?"
   ```

3. **Data Architect**: Consider database pre-aggregation
   ```
   "As the Data Architect, should we pre-aggregate metrics in the database
   before exporting to R? What aggregation strategy would reduce R processing
   time?"
   ```

4. **R Performance Expert**: Optimize identified bottlenecks
   ```
   "As the R Performance Expert, convert the slow data.frame operations to
   data.table and implement the optimization strategies identified."
   ```

**Common Causes**:
- ❌ Using data.frame instead of data.table
- ❌ Loops instead of vectorized operations
- ❌ Reading CSV multiple times
- ❌ No caching in R Markdown chunks
- ❌ Large object copies
- ❌ Inefficient ggplot2 rendering

**Common Fixes**:
- ✅ Use data.table: 10-100x speedup
- ✅ Vectorize operations: 100-1000x speedup
- ✅ Cache expensive chunks: Eliminate redundant computation
- ✅ Downsample before plotting: 10-50x rendering speedup

---

### Problem: "Cross-tenant data leak detected"

**Symptoms**:
- User from tenant A sees data from tenant B
- Database queries returning data across tenants
- Security audit failure

**Troubleshooting Workflow**:

1. **Security Architect**: Immediate containment
   ```
   "Security Architect: PRIORITY: Cross-tenant data leak detected. Immediate
   actions: 1) Disable affected endpoints 2) Audit all queries 3) Notify
   affected tenants 4) Begin forensic investigation."
   ```

2. **Django Tenants Specialist**: Audit tenant isolation
   ```
   "Django Tenants Specialist: Audit all database queries for proper tenant
   context. Identify queries that bypass tenant middleware."
   ```

3. **Backend Python Developer**: Review code
   ```
   "Backend Python Developer: Review all views, models, and queries for
   proper tenant filtering. Check for raw SQL that bypasses ORM."
   ```

4. **Security Architect**: Implement fixes
   ```
   "Security Architect: Implement mandatory tenant checks in all queries.
   Add database constraints to enforce tenant isolation."
   ```

5. **Data Quality Engineer**: Validate data integrity
   ```
   "Data Quality Engineer: Validate that all existing data is correctly
   associated with tenants. Identify any misassociated records."
   ```

**Common Causes**:
- ❌ Queries bypassing tenant middleware
- ❌ Raw SQL without tenant filter
- ❌ Admin interface not tenant-aware
- ❌ Background tasks missing tenant context
- ❌ API endpoints not checking tenant ownership

**Prevention**:
- ✅ Always use Django ORM (respects tenant context)
- ✅ If using raw SQL, always filter by tenant
- ✅ Test with multiple tenants
- ✅ Code review focused on tenant isolation
- ✅ Automated tests for tenant boundaries

---

### Problem: "Upload endpoint returning 500 errors"

**Symptoms**:
- HTTP 500 Internal Server Error
- Error logs show exceptions
- Upload client reporting failures

**Troubleshooting Workflow**:

1. **Integration Architect**: Coordinate debugging
   ```
   "Integration Architect: Upload endpoint returning 500 errors. Check logs,
   validate request format, test error handling."
   ```

2. **Backend Python Developer**: Check server logs
   ```bash
   # Check Django logs
   tail -f /var/log/django/error.log

   # Or Django dev server output
   python manage.py runserver
   ```

3. **API Architect**: Validate request format
   ```
   "API Architect: Validate the upload request matches the API specification.
   Check Content-Type, multipart boundaries, field names."
   ```

4. **Security Architect**: Check authentication
   ```
   "Security Architect: Verify the API key format, check for expired keys,
   validate Bearer token header format."
   ```

5. **Data Quality Engineer**: Check validation logic
   ```
   "Data Quality Engineer: Review validation code for exceptions. Ensure all
   validation errors return 400, not 500."
   ```

6. **Backend Python Developer**: Fix and test
   ```
   "Backend Python Developer: Based on error logs, fix the exception and add
   proper error handling. Return appropriate 4xx codes for client errors."
   ```

**Common Causes**:
- ❌ Unhandled exception in view
- ❌ Database connection failure
- ❌ Missing required field in request
- ❌ Validation raising exception instead of returning error
- ❌ Tenant not found (django-tenants issue)

---

### Problem: "pcc collecting incorrect metrics"

**Symptoms**:
- CPU percentages don't add to 100%
- Negative values in metrics
- Metrics seem unrealistic

**Troubleshooting Workflow**:

1. **Linux Systems Engineer**: Verify /proc parsing
   ```
   "Linux Systems Engineer: Review the /proc file format for the problematic
   metric. Provide the correct parsing logic and calculation formulas."
   ```

2. **Go Backend Developer**: Review parsing code
   ```
   "Go Backend Developer: Review the /proc parsing code for the affected
   metric. Check for off-by-one errors, incorrect field indexing, or
   calculation errors."
   ```

3. **Data Quality Engineer**: Add validation
   ```
   "Data Quality Engineer: Add validation rules to detect impossible values.
   For example, CPU percentages must be 0-100, memory cannot be negative."
   ```

4. **Go Backend Developer**: Implement fix
   ```
   "Go Backend Developer: Implement the correct parsing logic and add unit
   tests to verify accuracy against known /proc samples."
   ```

**Common Causes**:
- ❌ Incorrect field index in /proc file
- ❌ Not handling counter rollover
- ❌ Incorrect delta calculation (difference between samples)
- ❌ Time interval miscalculation
- ❌ Units mismatch (KB vs MB, bytes vs bits)

**Verification**:
```bash
# Compare pcc output with manual calculation
cat /proc/stat | head -1
# Compare with pcc JSON output

# Use sysstat for verification
mpstat 1 5  # Compare with pcc CPU metrics
iostat 1 5  # Compare with pcc disk metrics
```

---

## Quick Start Paths

### Path 1: I'm New to the Project

**Start Here**: Integration Architect

```
"Integration Architect: I'm new to the PerfAnalysis project. Can you explain
the overall architecture, data flow, and which components I should learn first?"
```

**Follow-up**: Solutions Architect
```
"Solutions Architect: What are the key architectural decisions in this system
and what deployment environments are supported?"
```

**Then**: Component-specific agents based on your role
- Go development → Go Backend Developer
- Django development → Backend Python Developer
- R development → R Performance Expert
- DevOps → DevOps Engineer

---

### Path 2: I'm Working on perfcollector2

**Primary Agents**:
- Go Backend Developer (implementation)
- Linux Systems Engineer (/proc metrics)

**Typical Questions**:

```
"Linux Systems Engineer: What metrics are available in /proc/meminfo and
which ones are most important for memory analysis?"

"Go Backend Developer: How do I add a new metric to the pcc collection loop?"

"Go Backend Developer: Implement retry logic with exponential backoff for
the upload client."
```

**Supporting Agents**:
- Configuration Management Specialist (configuration)
- Data Quality Engineer (validation)
- Integration Architect (upload workflow)

---

### Path 3: I'm Working on XATbackend

**Primary Agents**:
- Backend Python Developer (Django implementation)
- Django Tenants Specialist (multi-tenancy)

**Typical Questions**:

```
"Backend Python Developer: Create the upload API endpoint for performance
data with CSV file handling."

"Django Tenants Specialist: Ensure the upload endpoint properly isolates
data by tenant."

"Security Architect: Implement API key authentication for machine uploads."
```

**Supporting Agents**:
- Security Architect (authentication/authorization)
- DevOps Engineer (Azure deployment)
- Data Architect (database schema)
- API Architect (API design)

---

### Path 4: I'm Working on automated-Reporting

**Primary Agent**:
- R Performance Expert

**Typical Questions**:

```
"R Performance Expert: Optimize this data.frame operation that's processing
100K rows and taking 2 minutes."

"R Performance Expert: Convert this dplyr code to data.table for better
performance."

"R Performance Expert: Add a new visualization showing disk I/O patterns
over time."
```

**Supporting Agents**:
- Configuration Management Specialist (YAML config)
- Data Architect (data transformation)
- Automation Engineer (CLI interface)
- Oracle Developer (database integration - future)

---

### Path 5: I'm Working on Integration Between Components

**Primary Agent**:
- Integration Architect

**Typical Questions**:

```
"Integration Architect: Design the complete upload workflow from perfcollector2
to XATbackend including authentication, error handling, and retry logic."

"Integration Architect: Troubleshoot why data collected by pcc isn't appearing
in the generated reports."

"Integration Architect and Security Architect: Design the authenticated upload
API with proper tenant isolation."
```

**Supporting Agents**:
- Security Architect (security design)
- API Architect (API contracts)
- Component-specific agents (implementation)

---

### Path 6: I'm Deploying to Production

**Primary Agents**:
- DevOps Engineer (deployment)
- Solutions Architect (architecture)

**Typical Questions**:

```
"DevOps Engineer: Deploy XATbackend to Azure App Service with PostgreSQL,
configure monitoring, and set up CI/CD pipeline."

"Solutions Architect: Design the production architecture for 100 monitored
machines with high availability and disaster recovery."

"Security Architect: Implement production security including HTTPS, API key
rotation, and audit logging."
```

**Supporting Agents**:
- Security Architect (security hardening)
- Backend Python Developer (Django configuration)
- Data Architect (database scaling)

---

## Git Workflow

### Repository Structure

```
PerfAnalysis/               # Parent repository
├── .git/                   # Git repository
├── .gitmodules             # Submodule configuration
│
├── perfcollector2/         # Submodule (separate repo)
│   └── .git/               # Submodule git
│
├── XATbackend/             # Submodule (separate repo)
│   └── .git/               # Submodule git
│
├── automated-Reporting/    # Submodule (separate repo)
│   └── .git/               # Submodule git
│
└── claude-agents/          # Submodule (separate repo)
    └── .git/               # Submodule git
```

### Working with Submodules

**Clone the entire project**:
```bash
git clone --recurse-submodules https://github.com/yourusername/PerfAnalysis.git
cd PerfAnalysis
```

**Update submodules**:
```bash
# Update all submodules to latest
git submodule update --remote --merge

# Update specific submodule
cd perfcollector2
git pull origin main
cd ..
git add perfcollector2
git commit -m "Update perfcollector2 submodule"
```

**Make changes in a submodule**:
```bash
# Work in submodule
cd perfcollector2
git checkout -b feature/new-metric
# ... make changes ...
git add .
git commit -m "Add /proc/vmstat parsing"
git push origin feature/new-metric

# Update parent to reference new commit
cd ..
git add perfcollector2
git commit -m "Update perfcollector2: Add vmstat parsing"
git push
```

### Commit Guidelines

**DO** commit:
- Source code changes
- Configuration files
- Documentation updates
- Agent updates
- Database schema scripts

**DON'T** commit:
- Compiled binaries (perfcollector2/bin/)
- Generated reports (*.html, *.pdf)
- Data files (*.csv, *.json collections)
- Virtual environments (Python venv, R renv cache)
- API keys or secrets
- IDE configuration (.vscode/, .idea/)

### Gitignore Files

Each component should have appropriate .gitignore:

**perfcollector2/.gitignore**:
```
bin/
*.json
*.csv
*.log
```

**XATbackend/.gitignore**:
```
*.pyc
__pycache__/
.env
*.sqlite3
staticfiles/
media/
venv/
```

**automated-Reporting/.gitignore**:
```
*.html
*.pdf
*.tex
.RData
.Rhistory
renv/library/
reporting.log
```

---

## Environment Variables Reference

### perfcollector2 (Go)

**pcc (Client)**:
```bash
PCC_DURATION=24h          # Collection duration (e.g., 24h, 1h, 30m)
PCC_FREQUENCY=15s         # Sampling interval (e.g., 1s, 5s, 15s, 60s)
PCC_COLLECTION=~/pcc.json # Output file path
PCC_MODE=local            # Mode: local or trickle
PCC_APIKEY=<key>          # API key for trickle mode
PCC_SERVER=localhost:8080 # pcd server address (trickle mode)
```

**pcd (Server)**:
```bash
LISTENADDRESS=localhost:8080  # Server bind address
PCD_LOGLEVEL=info             # Log level: trace, debug, info, warn, error
PCD_APIKEYS_FILE=~/.pcd/apikeys  # Path to API keys file
```

**pcprocess (Processor)**:
```bash
PCR_COLLECTION=~/pcc.json  # Input JSON file
PCR_OUTDIR=~/output.csv    # Output CSV file
```

---

### XATbackend (Django)

**Django Settings**:
```bash
DEBUG=False                    # Debug mode (never True in production)
SECRET_KEY=<random-string>     # Django secret key (generate uniquely)
ALLOWED_HOSTS=portal.example.com,*.portal.example.com  # Allowed domains
DATABASE_URL=postgresql://user:pass@host:5432/dbname   # Database connection

# Multi-tenancy
TENANT_MODEL=tenants.Tenant
TENANT_DOMAIN_MODEL=tenants.Domain

# Security
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True

# Static files
STATIC_URL=/static/
STATIC_ROOT=/var/www/static/
MEDIA_URL=/media/
MEDIA_ROOT=/var/www/media/

# Azure (if using)
AZURE_ACCOUNT_NAME=<storage-account>
AZURE_ACCOUNT_KEY=<storage-key>
AZURE_CONTAINER=static
```

---

### automated-Reporting (R)

**R Environment**:
```bash
R_HOME=/usr/lib/R                  # R installation path
R_LIBS_USER=~/R/library            # User package library

# Report configuration (planned)
REPORT_CONFIG=/etc/perfmon/config.yaml  # Configuration file
REPORT_OUTPUT_DIR=/var/www/reports      # Output directory
REPORT_FORMAT=html                      # Output format: html, pdf, both

# Oracle connection (future)
ORACLE_HOST=localhost
ORACLE_PORT=1521
ORACLE_SERVICE=FREEPDB1
ORACLE_USER=perf_report_user
ORACLE_PASSWORD=<secure-password>
```

---

## Resources & Documentation

### Official Documentation

**Go**:
- [Go Language](https://go.dev/)
- [Go Standard Library](https://pkg.go.dev/std)
- [net/http Package](https://pkg.go.dev/net/http)

**Django**:
- [Django Documentation](https://docs.djangoproject.com/en/3.2/)
- [django-tenants Documentation](https://django-tenants.readthedocs.io/)
- [Django REST Framework](https://www.django-rest-framework.org/)

**R**:
- [R Project](https://www.r-project.org/)
- [R Markdown](https://rmarkdown.rstudio.com/)
- [ggplot2](https://ggplot2.tidyverse.org/)
- [data.table](https://rdatatable.gitlab.io/data.table/)

**Databases**:
- [PostgreSQL Documentation](https://www.postgresql.org/docs/12/)
- [Oracle Database 26ai Free](https://www.oracle.com/database/free/)

**Cloud**:
- [Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Database for PostgreSQL](https://docs.microsoft.com/en-us/azure/postgresql/)

### Project-Specific Documentation

**Root Project**:
- This file (`claude.md`) - Comprehensive project guide
- `agents/00-AGENT_DIRECTORY.md` - Agent quick reference
- `agents/AGENT_MANIFEST.yaml` - Detailed agent manifest
- `agents/README.md` - Agent usage guide

**perfcollector2**:
- `perfcollector2/README.md` - Component overview and usage

**XATbackend**:
- `XATbackend/README.md` - Django app documentation
- `XATbackend/docs/` - Additional documentation (if exists)

**automated-Reporting**:
- `automated-Reporting/claude.md` - Component-specific guide (669 lines)
- `automated-Reporting/README.md` - User documentation
- `automated-Reporting/ORACLE_INTEGRATION_GUIDE.md` - Oracle migration plan
- `automated-Reporting/QUICKSTART_ORACLE.md` - Quick setup guide

### Agent Files

All 16 agents are located in `/Users/danmcdougal/projects/PerfAnalysis/agents/`:

**Backend Development**:
- `agents/backend/go-backend-developer.md`
- `agents/backend/backend-python-developer.md`
- `agents/backend/django-tenants-specialist.md`

**Operational**:
- `agents/operational/linux-systems-engineer.md`
- `agents/operational/automation-engineer.md`
- `agents/operational/configuration-management-specialist.md`
- `agents/operational/data-quality-engineer.md`

**Performance**:
- `agents/performance/r-performance-expert.md`

**Database**:
- `agents/database/data-architect.md`
- `agents/database/time-series-architect.md`
- `agents/database/agent-oracle-developer.md`

**Integration**:
- `agents/integration/integration-architect.md`

**Architecture**:
- `agents/architecture/api-architect.md`
- `agents/architecture/security-architect.md`
- `agents/architecture/solutions-architect-sais.md`
- `agents/architecture/devops-engineer.md`

---

## Version History

| Version | Date | Changes | Agents |
|---------|------|---------|--------|
| 1.0 | 2026-01-04 | Initial comprehensive guide created | 16 agents |

---

## Final Reminders

### CRITICAL: Agent-First Workflow is MANDATORY

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  EVERY REQUEST MUST START WITH AGENT SELECTION                  │
│                                                                  │
│  1. Identify the appropriate agent(s)                           │
│  2. State which agent(s) you are invoking                       │
│  3. Provide context and constraints                             │
│  4. Request specific deliverables                               │
│                                                                  │
│  NO EXCEPTIONS. NO SHORTCUTS.                                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### When in Doubt

- **New to project?** → Integration Architect
- **Working on Go code?** → Go Backend Developer
- **Working on Django code?** → Backend Python Developer
- **Working on R code?** → R Performance Expert
- **Working across components?** → Integration Architect
- **Security question?** → Security Architect
- **Deployment question?** → DevOps Engineer
- **Database question?** → Data Architect

### Pro Tips

1. **Be specific** - Include technology, context, and desired outcome
2. **Provide examples** - Show sample data or code when possible
3. **Request deliverables** - Ask for specific outputs (code, config, docs)
4. **Use multiple agents** - Complex tasks require collaboration
5. **Test integration points** - Boundaries between components are critical

---

## Contact & Support

**Project Location**: `/Users/danmcdougal/projects/PerfAnalysis/`

**Agent Directory**: `/Users/danmcdougal/projects/PerfAnalysis/agents/`

**Last Updated**: 2026-01-04

**Agent Version**: 1.0

---

**This guide is designed for Claude Code. Use the agents extensively! They contain deep domain expertise specifically tailored for this project's needs.**

**Remember: ALWAYS start with agent selection. It's not optional. It's MANDATORY.**