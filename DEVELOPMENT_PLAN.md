# PerfAnalysis Development Plan

**Version**: 1.0
**Created**: 2026-01-04
**Duration**: 12 Weeks (3 Months)
**Methodology**: Agent-Driven Development

---

## Executive Summary

**Project**: PerfAnalysis Integrated Performance Monitoring Ecosystem

**Objective**: Build a production-ready, multi-component system that:
1. Collects Linux performance metrics automatically (perfcollector2 - Go)
2. Stores data in a secure multi-tenant portal (XATbackend - Django)
3. Generates rich visualization reports (automated-Reporting - R)
4. Integrates seamlessly across all three components

**Success Criteria**:
- ✅ Automated data collection with >99% uptime
- ✅ Secure multi-tenant data storage with zero data leaks
- ✅ Fast report generation (<30s for 24h data)
- ✅ Seamless integration with <1% error rate
- ✅ Production deployment on Azure

**Timeline**: 12 weeks across 4 phases
**Team Model**: 16 specialized AI agents with component ownership

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Phase 1: Foundation (Weeks 1-3)](#phase-1-foundation-weeks-1-3)
3. [Phase 2: Integration (Weeks 4-6)](#phase-2-integration-weeks-4-6)
4. [Phase 3: Production Readiness (Weeks 7-9)](#phase-3-production-readiness-weeks-7-9)
5. [Phase 4: Launch (Weeks 10-12)](#phase-4-launch-weeks-10-12)
6. [Success Metrics](#success-metrics)
7. [Risk Management](#risk-management)
8. [Resource Allocation](#resource-allocation)
9. [Post-Launch Roadmap](#post-launch-roadmap)

---

## Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                    PERFANALYSIS ECOSYSTEM                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ perfcollector2  │────────▶│   XATbackend    │────────▶│   automated-    │
│   (Go 1.21+)    │   CSV   │  (Django 3.2.3) │  Export │   Reporting     │
│                 │  Upload │                 │         │   (R 4.5.2)     │
│ • pcc client    │         │ • Multi-tenant  │         │                 │
│ • pcd server    │         │ • PostgreSQL    │         │ • R Markdown    │
│ • pcprocess     │         │ • Azure hosted  │         │ • ggplot2       │
│ • pcctl admin   │         │ • REST API      │         │ • Reports       │
└─────────────────┘         └─────────────────┘         └─────────────────┘
       │                            │                            │
       ▼                            ▼                            ▼
  Linux /proc              PostgreSQL 12.2                  CSV Files
  Metrics (1s)             Multi-tenant DB                  Visualization
```

### Data Flow

```
STAGE 1: COLLECTION
Linux /proc → pcc (poll 1-60s) → JSON buffer → pcprocess → CSV

STAGE 2: UPLOAD
CSV → HTTP POST → XATbackend /api/v1/performance/upload → PostgreSQL

STAGE 3: STORAGE
PostgreSQL (tenant-isolated schemas) → Performance data tables

STAGE 4: EXPORT
XATbackend export command → CSV → File system

STAGE 5: VISUALIZATION
R reads CSV → data.table processing → ggplot2 charts → HTML/PDF report
```

### Technology Stack

| Component | Language | Framework | Database | Deployment |
|-----------|----------|-----------|----------|------------|
| **perfcollector2** | Go 1.21+ | net/http, encoding/json | N/A | Linux servers |
| **XATbackend** | Python 3.x | Django 3.2.3, django-tenants | PostgreSQL 12.2 | Azure App Service |
| **automated-Reporting** | R 4.5.2 | R Markdown, ggplot2 | Oracle 26ai (future) | Scheduled execution |

---

## Phase 1: Foundation (Weeks 1-3)

**Goal**: Establish infrastructure and build core functionality for each component

### Week 1: Environment Setup & Architecture Validation

#### 1.1 Development Environment Setup
**Agent**: DevOps Engineer
**Duration**: 2 days

**Deliverables**:
- Docker Compose setup for local development
- PostgreSQL 12.2 container for XATbackend
- R 4.5.2 environment with all packages (via renv)
- Go 1.21+ toolchain installed
- IDE configurations (VS Code, RStudio)

**Acceptance Criteria**:
```bash
# All developers can run:
docker-compose up -d
make test-all  # All component tests pass
```

#### 1.2 Architecture Documentation
**Agents**: Solutions Architect + Integration Architect
**Duration**: 2 days

**Deliverables**:
1. **System Architecture Diagram** (Visio/draw.io):
   - Component boundaries
   - Data flows with formats
   - Integration points with protocols
   - Security boundaries

2. **API Contract Specifications**:
   ```yaml
   # CSV Format Standard
   columns:
     required:
       - timestamp (BIGINT, Unix epoch)
       - machine_id (VARCHAR 64)
       - cpu_user (FLOAT)
       - cpu_system (FLOAT)
       - cpu_idle (FLOAT)
       - mem_total (BIGINT)
       - mem_free (BIGINT)
     optional:
       - disk_<device>_reads (BIGINT)
       - net_<iface>_rx_bytes (BIGINT)

   # Upload Endpoint
   POST /api/v1/performance/upload
   Content-Type: multipart/form-data
   Authorization: Bearer {api_key}
   Fields:
     - file: CSV file
     - machine_id: string
     - tenant_id: UUID
   ```

3. **Security Architecture**:
   - Authentication flows
   - API key generation and storage
   - Multi-tenant isolation model
   - Secret management strategy

4. **Database Schema Design**:
   ```sql
   -- PostgreSQL Schema (per tenant)
   CREATE TABLE machines (
       id SERIAL PRIMARY KEY,
       machine_id VARCHAR(64) UNIQUE NOT NULL,
       name VARCHAR(128),
       created_at TIMESTAMP,
       last_seen TIMESTAMP
   );

   CREATE TABLE performance_data (
       id BIGSERIAL PRIMARY KEY,
       machine_id INT REFERENCES machines(id),
       timestamp BIGINT NOT NULL,
       cpu_user FLOAT,
       cpu_system FLOAT,
       cpu_idle FLOAT,
       mem_total BIGINT,
       mem_free BIGINT,
       disk_metrics JSONB,
       network_metrics JSONB
   );

   CREATE INDEX idx_perf_machine_ts ON performance_data(machine_id, timestamp);
   ```

**Acceptance Criteria**: Architecture review approved by all component agents

#### 1.3 CI/CD Pipeline Setup
**Agent**: DevOps Engineer
**Duration**: 2 days

**Deliverables**:
1. **GitHub Actions Workflows**:

   perfcollector2 (.github/workflows/go-ci.yml):
   ```yaml
   name: Go CI
   on: [push, pull_request]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: actions/setup-go@v4
           with:
             go-version: '1.21'
         - run: make test
         - run: make lint
         - run: make build
   ```

   XATbackend (.github/workflows/django-ci.yml):
   ```yaml
   name: Django CI
   on: [push, pull_request]
   jobs:
     test:
       runs-on: ubuntu-latest
       services:
         postgres:
           image: postgres:12.2
       steps:
         - uses: actions/checkout@v3
         - uses: actions/setup-python@v4
           with:
             python-version: '3.10'
         - run: pip install -r requirements.txt
         - run: python manage.py test
         - run: pylint apps/
   ```

   automated-Reporting (.github/workflows/r-ci.yml):
   ```yaml
   name: R CI
   on: [push, pull_request]
   jobs:
     test:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: r-lib/actions/setup-r@v2
           with:
             r-version: '4.5.2'
         - run: Rscript renv_init.R
         - run: Rscript -e "lintr::lint_dir()"
   ```

2. **Code Quality Gates**:
   - golangci-lint for Go
   - pylint + black for Python
   - lintr for R
   - Minimum coverage: 70% (increasing to 80%)

**Acceptance Criteria**: All CI pipelines green, quality gates passing

**Milestone M1**: Development environment operational, architecture documented, CI/CD functional

---

### Week 2-3: Core Component Development (Parallel)

#### Component 1: perfcollector2 (Go)

**Primary Agent**: Go Backend Developer
**Supporting Agents**: Linux Systems Engineer, Configuration Management Specialist

##### 2.1 Implement /proc Metric Parsers (3 days)

**Tasks**:
1. **CPU Parser** (parser/stat.go):
   ```go
   type CPUStat struct {
       User    uint64
       System  uint64
       Idle    uint64
       IOWait  uint64
       IRQ     uint64
       SoftIRQ uint64
   }

   func ParseCPUStat(data []byte) (*CPUStat, error)
   ```

2. **Memory Parser** (parser/meminfo.go):
   ```go
   type MemInfo struct {
       Total     uint64
       Free      uint64
       Available uint64
       Buffers   uint64
       Cached    uint64
   }

   func ParseMemInfo(data []byte) (*MemInfo, error)
   ```

3. **Disk I/O Parser** (parser/diskstats.go):
   ```go
   type DiskStats struct {
       Device      string
       Reads       uint64
       Writes      uint64
       ReadBytes   uint64
       WriteBytes  uint64
   }

   func ParseDiskStats(data []byte) ([]DiskStats, error)
   ```

4. **Network Parser** (parser/net_dev.go):
   ```go
   type NetStats struct {
       Interface string
       RxBytes   uint64
       TxBytes   uint64
       RxPackets uint64
       TxPackets uint64
   }

   func ParseNetDev(data []byte) ([]NetStats, error)
   ```

**Deliverables**:
- 4 parser modules with unit tests (>80% coverage)
- Benchmark tests for performance validation
- Error handling for malformed /proc data

**Acceptance Criteria**: All parsers tested on real /proc data from 3+ Linux distributions

##### 2.2 Build pcc Client (4 days)

**Features**:
1. **Configurable Collection**:
   ```bash
   export PCC_FREQUENCY=60s
   export PCC_DURATION=24h
   export PCC_MODE=local  # or trickle
   export PCC_COLLECTION=/data/pcc.json
   pcc
   ```

2. **Local Mode**: Buffer to JSON file
3. **Trickle Mode**: Stream to pcd server via HTTP
4. **Graceful Shutdown**: SIGINT/SIGTERM handling

**Deliverables**:
- Working pcc binary
- Configuration via env vars
- Signal handling
- Integration tests

**Acceptance Criteria**: 24-hour collection test passes without memory leaks

##### 2.3 Build pcprocess Processor (2 days)

**Features**:
1. Read JSON collection file
2. Convert to CSV with standardized columns
3. Handle device-specific metrics (disk_sda_*, net_eth0_*)

**Deliverables**:
```bash
pcprocess --input pcc.json --output perf_data.csv
# Output: CSV with columns compatible with R reporting
```

**Acceptance Criteria**: CSV readable by automated-Reporting without errors

##### 2.4 Configuration System (1 day)

**Features**:
1. Environment variables (highest priority)
2. Config file support (YAML/JSON)
3. Machine ID auto-detection
4. Defaults for all settings

**Deliverables**:
- Config module (config/config.go)
- Example config files
- Documentation

**Acceptance Criteria**: All binaries use centralized config

---

#### Component 2: XATbackend (Django)

**Primary Agent**: Backend Python Developer
**Supporting Agents**: Django Tenants Specialist, Security Architect

##### 2.5 Multi-Tenant Foundation (3 days)

**Tasks**:
1. **Configure django-tenants**:
   ```python
   # settings.py
   INSTALLED_APPS = [
       'django_tenants',
       # ...
   ]

   DATABASE_ROUTERS = ['django_tenants.routers.TenantSyncRouter']

   TENANT_MODEL = 'tenants.Tenant'
   TENANT_DOMAIN_MODEL = 'tenants.Domain'
   ```

2. **Tenant Model**:
   ```python
   from django_tenants.models import TenantMixin, DomainMixin

   class Tenant(TenantMixin):
       name = models.CharField(max_length=100)
       created_on = models.DateField(auto_now_add=True)

   class Domain(DomainMixin):
       pass
   ```

3. **Schema Creation**: Automatic schema per tenant

**Deliverables**:
- Multi-tenant framework working
- Tenant CRUD operations
- Schema isolation tests

**Acceptance Criteria**: Create 3 test tenants, verify schema isolation

##### 2.6 Machine Management Module (3 days)

**Models**:
```python
class Machine(models.Model):
    machine_id = models.CharField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    tenant = models.ForeignKey(Tenant, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    last_seen = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['machine_id']),
            models.Index(fields=['tenant', 'machine_id']),
        ]
```

**Views**:
- List machines (with tenant filter)
- Register new machine
- Update machine metadata
- Delete machine

**Deliverables**:
- Machine model with migrations
- REST API endpoints
- Admin UI for management

**Acceptance Criteria**: Can register 10 machines across 3 tenants

##### 2.7 Performance Data Upload API (4 days)

**Endpoint**:
```python
@csrf_exempt
@require_api_key
def upload_performance_data(request):
    """
    POST /api/v1/performance/upload
    """
    csv_file = request.FILES.get('file')
    machine_id = request.POST.get('machine_id')
    tenant_id = request.POST.get('tenant_id')

    # Validate tenant
    # Parse CSV with pandas
    # Validate schema
    # Bulk insert to database
    # Return response
```

**Features**:
1. CSV validation (schema, data types)
2. Bulk insert optimization (1000+ rows)
3. Error handling with detailed messages
4. Transaction management

**Deliverables**:
- Working upload endpoint
- API key authentication
- Comprehensive tests
- API documentation

**Acceptance Criteria**: Upload 10,000 rows in <10 seconds

---

#### Component 3: automated-Reporting (R)

**Primary Agent**: R Performance Expert
**Supporting Agents**: Data Architect, Configuration Management Specialist

##### 2.8 Remove Hardcoded Configuration (3 days)

**Current Problem**:
```r
# reporting.Rmd lines 24-30 (HARDCODED)
storeVol <- "sda"
netIface <- "ens33"
machName <- "machine001"
UUID <- "0001-001-002"
loc <- "testData/proc/"
```

**Solution**:
1. **YAML Configuration** (config.yaml):
   ```yaml
   machine:
     name: server01
     uuid: abc-123-def

   metrics:
     storage_device: auto  # or specific: sda
     network_interface: auto  # or specific: eth0

   paths:
     data_directory: /data/perf
     output_directory: /reports
   ```

2. **CLI Wrapper** (reporting_cli.R):
   ```r
   library(optparse)

   option_list <- list(
     make_option("--config", type="character", default="config.yaml"),
     make_option("--machine", type="character"),
     make_option("--data-dir", type="character"),
     make_option("--output", type="character", default="report.html")
   )

   opt <- parse_args(OptionParser(option_list=option_list))

   # Load config, override with CLI args
   # Render reporting.Rmd with params
   ```

3. **Auto-Detection**:
   ```r
   # R/device_detection.R
   detect_busiest_storage <- function() {
     # Parse /proc/diskstats
     # Find device with most I/O
   }

   detect_primary_interface <- function() {
     # Parse /proc/net/dev
     # Find interface with most traffic
   }
   ```

**Deliverables**:
- YAML config system
- CLI wrapper script
- Auto-detection functions
- Updated reporting.Rmd

**Acceptance Criteria**: Run report with zero hardcoded values

##### 2.9 Data Validation Module (2 days)

**Features**:
```r
library(assertr)

validate_performance_data <- function(df) {
  df %>%
    verify(nrow(.) > 0) %>%
    verify(has_all_names("timestamp", "cpu_user", "cpu_system")) %>%
    assert(within_bounds(0, 100), cpu_user, cpu_system, cpu_idle) %>%
    assert(not_na, timestamp) %>%
    assert_rows(num_row_NAs, within_bounds(0, 2), everything())
}

# Usage
data <- read_csv("perf_data.csv")
validated_data <- validate_performance_data(data)
```

**Deliverables**:
- Validation function library
- Quality metrics calculation
- Validation report section in output

**Acceptance Criteria**: Detect and report 5 common data issues

##### 2.10 Report Optimization (2 days)

**Optimizations**:
1. **Replace loops with vectorization**:
   ```r
   # BEFORE (slow)
   for (i in 1:nrow(cpu_data)) {
     cpu_data$utilization[i] <- 100 - cpu_data$idle[i]
   }

   # AFTER (fast)
   cpu_data$utilization <- 100 - cpu_data$idle
   ```

2. **Use data.table**:
   ```r
   library(data.table)
   dt <- as.data.table(perf_data)

   # Fast aggregation
   dt[, .(avg_cpu = mean(cpu_user),
          max_mem = max(mem_used)),
      by = .(hour = hour(timestamp))]
   ```

3. **Cache expensive computations**:
   ```r
   # R Markdown chunk
   ```{r percentiles, cache=TRUE}
   percentiles <- calculate_percentiles(large_dataset)
   ```
   ```

**Deliverables**:
- Optimized data processing
- Profiling report (profvis)
- Benchmark comparison

**Acceptance Criteria**: Report generation <30s for 100K rows (down from 2+ minutes)

**Milestone M2**: All 3 components have working MVPs

---

## Phase 2: Integration (Weeks 4-6)

**Goal**: Connect components and implement end-to-end workflows

### Week 4: Integration Development

#### 3.1 perfcollector2 → XATbackend Integration (4 days)

**Agents**: Integration Architect + Go Backend Developer + Backend Python Developer + Security Architect

**Implementation**:

1. **Upload Client in perfcollector2** (uploader/xatbackend.go):
   ```go
   type XATConfig struct {
       BaseURL   string
       APIKey    string
       TenantID  string
       MachineID string
       Timeout   time.Duration
   }

   func UploadCSV(cfg XATConfig, csvPath string) error {
       // Open CSV file
       // Create multipart form
       // Add metadata (machine_id, tenant_id)
       // Send POST request
       // Handle response
   }
   ```

2. **Retry Logic**:
   ```go
   func UploadWithRetry(cfg XATConfig, csvPath string, maxRetries int) error {
       for attempt := 0; attempt <= maxRetries; attempt++ {
           err := UploadCSV(cfg, csvPath)
           if err == nil {
               return nil
           }

           backoff := time.Duration(math.Pow(2, float64(attempt))) * time.Second
           time.Sleep(backoff)
       }
       return fmt.Errorf("upload failed after %d attempts", maxRetries)
   }
   ```

3. **Authentication**:
   ```go
   req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", cfg.APIKey))
   ```

4. **Error Handling**:
   ```go
   type UploadResponse struct {
       Status       string `json:"status"`
       UploadID     string `json:"upload_id"`
       RowsImported int    `json:"rows_imported"`
       Error        string `json:"error,omitempty"`
   }
   ```

**Deliverables**:
- Upload module in perfcollector2
- Integration tests
- Error handling and logging
- Retry with exponential backoff

**Acceptance Criteria**: Successfully upload 10 CSVs with 100% success rate

#### 3.2 XATbackend → automated-Reporting Integration (3 days)

**Agents**: Integration Architect + Backend Python Developer + R Performance Expert

**Implementation**:

1. **Django Management Command** (management/commands/export_perf_data.py):
   ```python
   from django.core.management.base import BaseCommand
   import pandas as pd

   class Command(BaseCommand):
       def add_arguments(self, parser):
           parser.add_argument('--machine-id', required=True)
           parser.add_argument('--start-date', required=True)
           parser.add_argument('--end-date', required=True)
           parser.add_argument('--output', required=True)

       def handle(self, *args, **options):
           # Query PerformanceData
           # Convert to DataFrame
           # Export to CSV
           # Log success
   ```

2. **REST API** (future):
   ```python
   @api_view(['GET'])
   @require_api_key
   def export_data(request):
       machine_id = request.GET.get('machine_id')
       start = request.GET.get('start')
       end = request.GET.get('end')

       # Generate temporary export file
       # Return presigned URL
       # Schedule cleanup
   ```

3. **CSV Format Validation**:
   ```python
   REQUIRED_COLUMNS = [
       'timestamp', 'machine_id',
       'cpu_user', 'cpu_system', 'cpu_idle',
       'mem_total', 'mem_free'
   ]

   def validate_export_format(df):
       missing = set(REQUIRED_COLUMNS) - set(df.columns)
       if missing:
           raise ValueError(f"Missing columns: {missing}")
   ```

**Deliverables**:
- Export management command
- CSV format standardization
- Integration tests
- Documentation

**Acceptance Criteria**: Export 10,000 rows, successfully generate report in R

#### 3.3 API Key Management (3 days)

**Agent**: Security Architect

**Implementation**:

1. **API Key Model**:
   ```python
   import secrets
   import hashlib

   class APIKey(models.Model):
       user = models.ForeignKey(User, on_delete=models.CASCADE)
       name = models.CharField(max_length=100)
       key_hash = models.CharField(max_length=64, unique=True)
       created_at = models.DateTimeField(auto_now_add=True)
       last_used = models.DateTimeField(null=True)
       is_active = models.BooleanField(default=True)

       @staticmethod
       def generate_key():
           return secrets.token_urlsafe(32)

       @staticmethod
       def hash_key(key):
           return hashlib.sha256(key.encode()).hexdigest()
   ```

2. **Key Generation Endpoint**:
   ```python
   @login_required
   def generate_api_key(request):
       key = APIKey.generate_key()
       api_key = APIKey.objects.create(
           user=request.user,
           name=request.POST.get('name'),
           key_hash=APIKey.hash_key(key)
       )

       # Return key ONCE (never stored plaintext)
       return JsonResponse({'api_key': key})
   ```

3. **Validation Middleware**:
   ```python
   def require_api_key(view_func):
       def wrapper(request, *args, **kwargs):
           auth_header = request.headers.get('Authorization', '')
           if not auth_header.startswith('Bearer '):
               return JsonResponse({'error': 'Missing API key'}, status=401)

           key = auth_header[7:]
           key_hash = APIKey.hash_key(key)

           try:
               api_key = APIKey.objects.get(key_hash=key_hash, is_active=True)
               api_key.last_used = timezone.now()
               api_key.save()
               request.user = api_key.user
               return view_func(request, *args, **kwargs)
           except APIKey.DoesNotExist:
               return JsonResponse({'error': 'Invalid API key'}, status=401)

       return wrapper
   ```

**Deliverables**:
- API key model and migrations
- Generation endpoint
- Validation middleware
- Key rotation procedures
- Admin UI for key management

**Acceptance Criteria**:
- Generate 10 API keys
- Validate authentication works
- Test key revocation

**Milestone M3**: All integration points functional, authentication implemented

---

### Week 5-6: End-to-End Testing & Automation

#### 4.1 End-to-End Integration Test (3 days)

**Agent**: Integration Architect

**Test Script** (test_e2e.sh):
```bash
#!/bin/bash
set -e

echo "=== PerfAnalysis End-to-End Integration Test ==="

# Step 1: Collect data with pcc (5 minutes)
echo "[1/6] Collecting performance data..."
PCC_DURATION=5m PCC_FREQUENCY=10s PCC_MODE=local \
  PCC_COLLECTION=/tmp/e2e_pcc.json pcc

# Step 2: Process to CSV
echo "[2/6] Processing to CSV..."
pcprocess --input /tmp/e2e_pcc.json --output /tmp/e2e_data.csv

# Step 3: Upload to XATbackend
echo "[3/6] Uploading to XATbackend..."
curl -X POST \
  -H "Authorization: Bearer ${E2E_API_KEY}" \
  -F "file=@/tmp/e2e_data.csv" \
  -F "machine_id=e2e-test-machine" \
  -F "tenant_id=${E2E_TENANT_ID}" \
  ${XATBACKEND_URL}/api/v1/performance/upload

# Step 4: Verify data in database
echo "[4/6] Verifying data in database..."
python manage.py shell <<EOF
from apps.performance.models import PerformanceData
count = PerformanceData.objects.filter(machine__machine_id='e2e-test-machine').count()
assert count > 0, f"Expected data in database, found {count} rows"
print(f"✅ Found {count} rows in database")
EOF

# Step 5: Export data
echo "[5/6] Exporting data for reporting..."
python manage.py export_perf_data \
  --machine-id=e2e-test-machine \
  --start-date=$(date -d '1 hour ago' +%Y-%m-%d) \
  --end-date=$(date +%Y-%m-%d) \
  --output=/tmp/e2e_export.csv

# Step 6: Generate report
echo "[6/6] Generating R report..."
Rscript reporting_cli.R \
  --data-file=/tmp/e2e_export.csv \
  --output=/tmp/e2e_report.html

# Verify report exists
test -f /tmp/e2e_report.html || { echo "❌ Report not generated"; exit 1; }

echo "=== ✅ End-to-End Test PASSED ==="
```

**Deliverables**:
- Automated E2E test script
- Data validation at each stage
- Performance benchmarks
- Documentation

**Acceptance Criteria**: E2E test passes in <10 minutes

#### 4.2 Automation & Scheduling (3 days)

**Agent**: Automation Engineer

**Implementation**:

1. **Systemd Service** (perfcollector.service):
   ```ini
   [Unit]
   Description=PerfCollector Performance Metrics Collection
   After=network.target

   [Service]
   Type=simple
   User=perfmon
   Environment="PCC_FREQUENCY=60s"
   Environment="PCC_DURATION=infinity"
   Environment="PCC_MODE=trickle"
   EnvironmentFile=/etc/perfcollector/config.env
   ExecStart=/usr/local/bin/pcc
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target
   ```

2. **Systemd Timer** (perfcollector-upload.timer):
   ```ini
   [Unit]
   Description=Upload performance data every hour

   [Timer]
   OnBootSec=5min
   OnUnitActiveSec=1h

   [Install]
   WantedBy=timers.target
   ```

3. **Upload Service** (perfcollector-upload.service):
   ```ini
   [Unit]
   Description=Upload performance data to XATbackend

   [Service]
   Type=oneshot
   User=perfmon
   EnvironmentFile=/etc/perfcollector/config.env
   ExecStart=/usr/local/bin/upload-perf-data.sh
   ```

4. **Upload Script** (upload-perf-data.sh):
   ```bash
   #!/bin/bash

   DATA_DIR=/var/lib/perfcollector
   LATEST_JSON=$(ls -t ${DATA_DIR}/*.json | head -1)

   # Process to CSV
   pcprocess --input ${LATEST_JSON} --output ${DATA_DIR}/latest.csv

   # Upload with retry
   MAX_RETRIES=3
   for i in $(seq 1 $MAX_RETRIES); do
       if curl -X POST \
           -H "Authorization: Bearer ${XATBACKEND_API_KEY}" \
           -F "file=@${DATA_DIR}/latest.csv" \
           -F "machine_id=${MACHINE_ID}" \
           -F "tenant_id=${TENANT_ID}" \
           ${XATBACKEND_URL}/api/v1/performance/upload; then
           echo "Upload successful"
           exit 0
       fi
       echo "Retry $i/$MAX_RETRIES"
       sleep $((2 ** $i))
   done

   echo "Upload failed after $MAX_RETRIES attempts"
   exit 1
   ```

**Deliverables**:
- Systemd service files
- Upload automation script
- Installation documentation
- Monitoring integration

**Acceptance Criteria**: System runs unattended for 24 hours

#### 4.3 Data Quality Monitoring (4 days)

**Agent**: Data Quality Engineer

**Implementation**:

1. **Quality Metrics**:
   ```python
   from apps.monitoring.models import DataQualityMetric

   def calculate_quality_metrics(performance_data_qs):
       metrics = {
           'total_rows': performance_data_qs.count(),
           'null_percentage': calculate_null_percentage(performance_data_qs),
           'outlier_count': detect_outliers(performance_data_qs),
           'duplicate_count': detect_duplicates(performance_data_qs),
           'time_gaps': detect_time_gaps(performance_data_qs),
       }

       DataQualityMetric.objects.create(
           machine=machine,
           date=date.today(),
           **metrics
       )
   ```

2. **Validation Rules**:
   ```python
   VALIDATION_RULES = [
       ('cpu_user', 'within_bounds', (0, 100)),
       ('cpu_system', 'within_bounds', (0, 100)),
       ('mem_total', 'not_null', None),
       ('timestamp', 'not_null', None),
       ('timestamp', 'increasing', None),
   ]

   def validate_data(df, rules):
       violations = []
       for column, rule_type, params in rules:
           if rule_type == 'within_bounds':
               violations += check_bounds(df[column], params)
           elif rule_type == 'not_null':
               violations += check_not_null(df[column])
           # ... more rules
       return violations
   ```

3. **Alerting**:
   ```python
   if metrics['null_percentage'] > 5:
       send_alert(
           severity='warning',
           message=f"High null percentage: {metrics['null_percentage']}%",
           machine=machine
       )
   ```

**Deliverables**:
- Quality metrics dashboard
- Validation rule engine
- Alerting system
- Quality report integration

**Acceptance Criteria**: Detect 5 common data quality issues

**Milestone M4**: E2E pipeline validated, automation working, quality monitoring operational

---

## Phase 3: Production Readiness (Weeks 7-9)

**Goal**: Harden system for production deployment

### Week 7: Security Hardening

#### 5.1 Security Audit (3 days)

**Agent**: Security Architect

**Audit Checklist**:

1. **OWASP Top 10 Review**:
   - [ ] Injection (SQL, Command)
   - [ ] Broken Authentication
   - [ ] Sensitive Data Exposure
   - [ ] XML External Entities (N/A)
   - [ ] Broken Access Control
   - [ ] Security Misconfiguration
   - [ ] Cross-Site Scripting (XSS)
   - [ ] Insecure Deserialization
   - [ ] Using Components with Known Vulnerabilities
   - [ ] Insufficient Logging & Monitoring

2. **Code Review**:
   - Static analysis (bandit for Python, gosec for Go)
   - Dependency vulnerability scan (Snyk, Dependabot)
   - Secret detection (gitleaks)

3. **Penetration Testing**:
   - Automated scan (OWASP ZAP)
   - Manual testing of critical endpoints
   - API fuzzing

**Deliverables**:
- Security assessment report
- Vulnerability list with severity ratings
- Remediation plan with priorities
- Compliance checklist

**Acceptance Criteria**: No critical or high severity vulnerabilities

#### 5.2 Security Implementation (5 days)

**Tasks**:

1. **Input Validation** (Backend Python Developer):
   ```python
   from django.core.validators import RegexValidator

   class MachineIDValidator(RegexValidator):
       regex = r'^[a-zA-Z0-9_-]{1,64}$'
       message = 'Machine ID must be alphanumeric, dash, or underscore'

   def validate_csv_upload(csv_file):
       # File size check
       if csv_file.size > 100 * 1024 * 1024:  # 100MB
           raise ValidationError("File too large")

       # Content type check
       if not csv_file.content_type == 'text/csv':
           raise ValidationError("Must be CSV file")

       # Schema validation
       df = pd.read_csv(csv_file)
       required_columns = ['timestamp', 'machine_id', 'cpu_user']
       if not all(col in df.columns for col in required_columns):
           raise ValidationError("Missing required columns")
   ```

2. **SQL Injection Prevention** (Backend Python Developer):
   ```python
   # ✅ CORRECT: Use ORM
   PerformanceData.objects.filter(machine_id=machine_id)

   # ✅ CORRECT: Parameterized queries
   cursor.execute("SELECT * FROM performance_data WHERE machine_id = %s", [machine_id])

   # ❌ WRONG: String interpolation
   cursor.execute(f"SELECT * FROM performance_data WHERE machine_id = '{machine_id}'")
   ```

3. **CSRF Protection** (Backend Python Developer):
   ```python
   # Ensure CSRF middleware enabled
   MIDDLEWARE = [
       'django.middleware.csrf.CsrfViewMiddleware',
       # ...
   ]

   # API endpoints use CSRF exempt with API key auth
   @csrf_exempt
   @require_api_key
   def upload_performance_data(request):
       # API key provides authentication
   ```

4. **Rate Limiting** (Backend Python Developer):
   ```python
   from django_ratelimit.decorators import ratelimit

   @ratelimit(key='user', rate='100/h', method='POST')
   @require_api_key
   def upload_performance_data(request):
       # Max 100 uploads per hour per user
   ```

5. **Secrets Management** (DevOps Engineer):
   ```python
   # ✅ CORRECT: Use Azure Key Vault
   from azure.keyvault.secrets import SecretClient
   from azure.identity import DefaultAzureCredential

   credential = DefaultAzureCredential()
   client = SecretClient(vault_url="https://perfanalysis-kv.vault.azure.net/",
                         credential=credential)

   db_password = client.get_secret("database-password").value

   # ❌ WRONG: Hardcoded in settings.py
   DATABASE_PASSWORD = "super_secret_password"
   ```

**Deliverables**:
- Input validation on all endpoints
- SQL injection prevention verified
- CSRF protection enabled
- Rate limiting implemented
- Secrets moved to Azure Key Vault
- Security test suite

**Acceptance Criteria**: All security findings resolved, re-scan shows no critical/high issues

#### 5.3 Multi-Tenant Security Validation (2 days)

**Agent**: Django Tenants Specialist

**Tests**:

1. **Schema Isolation Test**:
   ```python
   def test_cross_tenant_isolation():
       # Create data in tenant1
       with tenant_context(tenant1):
           Machine.objects.create(machine_id='tenant1-machine')

       # Attempt to access from tenant2
       with tenant_context(tenant2):
           count = Machine.objects.filter(machine_id='tenant1-machine').count()
           assert count == 0, "Cross-tenant data leak detected!"
   ```

2. **API Endpoint Tenant Enforcement**:
   ```python
   def test_upload_endpoint_tenant_check():
       # User from tenant1 attempts to upload to tenant2
       response = client.post(
           '/api/v1/performance/upload',
           data={
               'file': csv_file,
               'machine_id': 'machine1',
               'tenant_id': tenant2.id  # Different tenant!
           },
           HTTP_AUTHORIZATION=f'Bearer {tenant1_api_key}'
       )
       assert response.status_code == 403  # Forbidden
   ```

3. **SQL Query Analysis**:
   ```python
   # Ensure all queries include tenant filter
   from django.test.utils import override_settings
   from django.db import connection

   with override_settings(DEBUG=True):
       with tenant_context(tenant1):
           list(Machine.objects.all())

       queries = connection.queries
       for query in queries:
           assert 'schema_name' in query['sql'], \
               f"Query missing tenant filter: {query['sql']}"
   ```

**Deliverables**:
- Cross-tenant isolation test suite
- SQL query audit
- Tenant boundary enforcement validation
- Security report

**Acceptance Criteria**: Zero cross-tenant data leaks in 100+ test scenarios

**Milestone M5**: Security audit complete, all findings resolved, multi-tenant security validated

---

### Week 8: Performance Optimization

#### 6.1 perfcollector2 Optimization (3 days)

**Agent**: Go Backend Developer

**Optimizations**:

1. **Memory Usage**:
   ```go
   // Before: Growing buffer
   var measurements []Measurement
   for {
       m := collectMeasurement()
       measurements = append(measurements, m)  // Unbounded growth
   }

   // After: Circular buffer with flush
   const bufferSize = 10000
   buffer := make([]Measurement, 0, bufferSize)

   for {
       m := collectMeasurement()
       buffer = append(buffer, m)

       if len(buffer) >= bufferSize {
           flushToFile(buffer)
           buffer = buffer[:0]  // Clear but keep capacity
       }
   }
   ```

2. **Goroutine Management**:
   ```go
   // Use worker pool pattern
   type WorkerPool struct {
       workers  int
       tasks    chan Task
       wg       sync.WaitGroup
   }

   func (p *WorkerPool) Start() {
       for i := 0; i < p.workers; i++ {
           p.wg.Add(1)
           go p.worker()
       }
   }

   func (p *WorkerPool) worker() {
       defer p.wg.Done()
       for task := range p.tasks {
           task.Execute()
       }
   }
   ```

3. **Efficient Parsing**:
   ```go
   // Use bufio.Scanner for line-by-line
   scanner := bufio.NewScanner(bytes.NewReader(data))
   for scanner.Scan() {
       line := scanner.Bytes()  // No allocation
       parseLine(line)
   }
   ```

**Benchmarks**:
```bash
go test -bench=. -benchmem ./parser/
go test -bench=. -benchmem ./measurement/
```

**Deliverables**:
- Optimized code with benchmarks
- Memory profiling report (pprof)
- CPU profiling report
- Documentation of optimizations

**Acceptance Criteria**:
- Memory usage < 50MB during 24h collection
- CPU usage < 5% average
- No memory leaks (run 7 days)

#### 6.2 XATbackend Optimization (3 days)

**Agents**: Backend Python Developer + Data Architect

**Optimizations**:

1. **Database Query Optimization**:
   ```python
   # Before: N+1 query problem
   machines = Machine.objects.all()
   for machine in machines:
       latest_data = machine.performancedata_set.latest('timestamp')  # N queries!

   # After: Use select_related / prefetch_related
   from django.db.models import Prefetch

   machines = Machine.objects.prefetch_related(
       Prefetch('performancedata_set',
                queryset=PerformanceData.objects.order_by('-timestamp')[:1],
                to_attr='latest_data')
   )
   ```

2. **Index Strategy**:
   ```python
   class Meta:
       indexes = [
           models.Index(fields=['machine', 'timestamp']),  # Common query
           models.Index(fields=['timestamp']),              # Time range queries
           models.Index(fields=['machine', '-timestamp']),  # Latest data
       ]
   ```

3. **Connection Pooling**:
   ```python
   DATABASES = {
       'default': {
           'ENGINE': 'django.db.backends.postgresql',
           'CONN_MAX_AGE': 600,  # 10 minutes
           'OPTIONS': {
               'connect_timeout': 10,
               'options': '-c statement_timeout=30000'  # 30s
           }
       }
   }
   ```

4. **Bulk Insert Optimization**:
   ```python
   # Use bulk_create for CSV upload
   def upload_csv_data(csv_file, machine):
       df = pd.read_csv(csv_file)

       objects = [
           PerformanceData(
               machine=machine,
               timestamp=row['timestamp'],
               cpu_user=row.get('cpu_user'),
               # ... other fields
           )
           for _, row in df.iterrows()
       ]

       # Bulk insert in batches
       batch_size = 1000
       PerformanceData.objects.bulk_create(objects, batch_size=batch_size)
   ```

**Deliverables**:
- Query optimization report
- Index implementation
- Connection pooling configuration
- Load test results

**Acceptance Criteria**:
- Upload API: 1000 rows/sec
- Query API: p95 < 100ms
- No N+1 queries (verified with django-debug-toolbar)

#### 6.3 R Reporting Optimization (4 days)

**Agent**: R Performance Expert

**Optimizations**:

1. **Use data.table**:
   ```r
   library(data.table)

   # Before: data.frame (slow)
   perf_data <- read.csv("large_file.csv")
   perf_data$utilization <- 100 - perf_data$cpu_idle
   result <- aggregate(utilization ~ hour, data=perf_data, FUN=mean)

   # After: data.table (fast)
   perf_dt <- fread("large_file.csv")
   perf_dt[, utilization := 100 - cpu_idle]
   result <- perf_dt[, .(avg_util = mean(utilization)), by = hour]
   ```

2. **Vectorization**:
   ```r
   # Before: Loop (very slow)
   percentiles <- numeric(length(metrics))
   for (i in seq_along(metrics)) {
       percentiles[i] <- quantile(data[[metrics[i]]], 0.95)
   }

   # After: Vectorized (fast)
   percentiles <- sapply(data[metrics], quantile, probs = 0.95)
   ```

3. **Caching**:
   ```r
   # R Markdown chunk with cache
   ```{r expensive_calculation, cache=TRUE, cache.extra=tools::md5sum("data.csv")}
   # This only runs when data.csv changes
   large_model <- compute_intensive_model(data)
   ```
   ```

4. **Parallel Processing**:
   ```r
   library(parallel)

   # Use multiple cores for independent calculations
   cl <- makeCluster(detectCores() - 1)
   clusterExport(cl, c("data", "helper_function"))

   results <- parLapply(cl, machine_list, function(machine) {
       analyze_machine(data[data$machine_id == machine, ])
   })

   stopCluster(cl)
   ```

**Profiling**:
```r
library(profvis)

profvis({
  # Run report generation
  rmarkdown::render("reporting.Rmd")
})
```

**Deliverables**:
- Optimized R code
- Profiling report showing improvements
- Benchmark comparison (before/after)
- Documentation of optimizations

**Acceptance Criteria**:
- Report generation: <30s for 100K rows (was 2+ minutes)
- Memory usage: <2GB (was 4GB+)
- Profiling shows no hot spots >5% runtime

**Milestone M6**: All performance targets met across components

---

### Week 9: Deployment Preparation

#### 7.1 Azure Infrastructure Setup (3 days)

**Agent**: DevOps Engineer

**Infrastructure as Code** (Terraform):

```hcl
# main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "perfanalysis" {
  name     = "perfanalysis-rg"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "perfanalysis" {
  name                = "perfanalysis-vnet"
  resource_group_name = azurerm_resource_group.perfanalysis.name
  location            = azurerm_resource_group.perfanalysis.location
  address_space       = ["10.0.0.0/16"]
}

# Subnet for App Service
resource "azurerm_subnet" "app_service" {
  name                 = "app-service-subnet"
  resource_group_name  = azurerm_resource_group.perfanalysis.name
  virtual_network_name = azurerm_virtual_network.perfanalysis.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "app-service-delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

# Subnet for PostgreSQL
resource "azurerm_subnet" "database" {
  name                 = "database-subnet"
  resource_group_name  = azurerm_resource_group.perfanalysis.name
  virtual_network_name = azurerm_virtual_network.perfanalysis.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "perfanalysis" {
  name                   = "perfanalysis-db"
  resource_group_name    = azurerm_resource_group.perfanalysis.name
  location               = azurerm_resource_group.perfanalysis.location
  version                = "12"
  administrator_login    = "perfadmin"
  administrator_password = var.db_password  # From Key Vault

  storage_mb = 32768  # 32GB
  sku_name   = "B_Standard_B1ms"  # Burstable, 1 vCore, 2GB RAM

  backup_retention_days = 7
  geo_redundant_backup_enabled = false

  delegated_subnet_id = azurerm_subnet.database.id
}

# App Service Plan
resource "azurerm_service_plan" "perfanalysis" {
  name                = "perfanalysis-plan"
  resource_group_name = azurerm_resource_group.perfanalysis.name
  location            = azurerm_resource_group.perfanalysis.location
  os_type             = "Linux"
  sku_name            = "B2"  # Basic, 2 cores, 3.5GB RAM
}

# App Service (XATbackend)
resource "azurerm_linux_web_app" "xatbackend" {
  name                = "perfanalysis-backend"
  resource_group_name = azurerm_resource_group.perfanalysis.name
  location            = azurerm_resource_group.perfanalysis.location
  service_plan_id     = azurerm_service_plan.perfanalysis.id

  site_config {
    application_stack {
      python_version = "3.10"
    }

    always_on = true
    health_check_path = "/health"
  }

  app_settings = {
    "DJANGO_SETTINGS_MODULE" = "config.settings.production"
    "DATABASE_URL" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_url.id})"
    "SECRET_KEY"   = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.secret_key.id})"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Key Vault
resource "azurerm_key_vault" "perfanalysis" {
  name                = "perfanalysis-kv"
  resource_group_name = azurerm_resource_group.perfanalysis.name
  location            = azurerm_resource_group.perfanalysis.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_web_app.xatbackend.identity[0].principal_id

    secret_permissions = ["Get", "List"]
  }
}

# Application Insights
resource "azurerm_application_insights" "perfanalysis" {
  name                = "perfanalysis-insights"
  resource_group_name = azurerm_resource_group.perfanalysis.name
  location            = azurerm_resource_group.perfanalysis.location
  application_type    = "web"
}
```

**Deliverables**:
- Terraform configurations
- Azure resources provisioned
- Network security configured
- Monitoring enabled

**Acceptance Criteria**: Infrastructure deployed, health checks passing

#### 7.2 Deployment Automation (3 days)

**Agent**: DevOps Engineer

**GitHub Actions Workflow** (.github/workflows/deploy-production.yml):

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  AZURE_WEBAPP_NAME: perfanalysis-backend
  PYTHON_VERSION: '3.10'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run tests
        run: |
          python manage.py test

      - name: Collect static files
        run: |
          python manage.py collectstatic --noinput

      - name: Create deployment package
        run: |
          zip -r deploy.zip . -x "*.git*" "*.github*" "tests/*"

      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: python-app
          path: deploy.zip

  deploy:
    runs-on: ubuntu-latest
    needs: build
    environment:
      name: 'Production'
      url: ${{ steps.deploy-to-webapp.outputs.webapp-url }}

    steps:
      - name: Download artifact
        uses: actions/download-artifact@v3
        with:
          name: python-app

      - name: Unzip artifact
        run: unzip deploy.zip

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy to Azure Web App
        id: deploy-to-webapp
        uses: azure/webapps-deploy@v2
        with:
          app-name: ${{ env.AZURE_WEBAPP_NAME }}
          package: .

      - name: Run database migrations
        run: |
          az webapp ssh --name ${{ env.AZURE_WEBAPP_NAME }} \
                        --resource-group perfanalysis-rg \
                        --command "python manage.py migrate --noinput"

      - name: Health check
        run: |
          for i in {1..10}; do
            status=$(curl -s -o /dev/null -w "%{http_code}" \
                     https://${{ env.AZURE_WEBAPP_NAME }}.azurewebsites.net/health)
            if [ $status -eq 200 ]; then
              echo "✅ Health check passed"
              exit 0
            fi
            echo "Waiting for app to be healthy... ($i/10)"
            sleep 10
          done
          echo "❌ Health check failed"
          exit 1
```

**Blue-Green Deployment Strategy**:
```yaml
# Deployment slots for zero-downtime
az webapp deployment slot create \
  --name perfanalysis-backend \
  --resource-group perfanalysis-rg \
  --slot staging

# Deploy to staging slot first
# Run smoke tests
# Swap staging to production
az webapp deployment slot swap \
  --name perfanalysis-backend \
  --resource-group perfanalysis-rg \
  --slot staging \
  --target-slot production
```

**Deliverables**:
- GitHub Actions workflow
- Blue-green deployment setup
- Rollback procedures
- Deployment documentation

**Acceptance Criteria**: Automated deployment succeeds, rollback tested

#### 7.3 Documentation (4 days)

**Agents**: All agents contributing

**Documentation Structure**:

```
docs/
├── installation/
│   ├── perfcollector2.md        # Go Backend Developer
│   ├── xatbackend.md            # Backend Python Developer
│   └── automated-reporting.md   # R Performance Expert
│
├── user-guide/
│   ├── getting-started.md
│   ├── register-machine.md
│   ├── view-reports.md
│   └── api-reference.md         # API Architect
│
├── operations/
│   ├── deployment.md            # DevOps Engineer
│   ├── monitoring.md            # DevOps Engineer
│   ├── backup-restore.md        # Data Architect
│   └── troubleshooting.md       # Integration Architect
│
├── security/
│   ├── authentication.md        # Security Architect
│   ├── multi-tenancy.md         # Django Tenants Specialist
│   └── api-keys.md              # Security Architect
│
└── development/
    ├── architecture.md          # Solutions Architect
    ├── contributing.md
    ├── testing.md
    └── agent-guide.md           # Reference to agents/
```

**Key Documentation**:

1. **Installation Guide** (perfcollector2):
   ```markdown
   # perfcollector2 Installation

   ## Prerequisites
   - Linux system (Ubuntu 20.04+, RHEL 8+, etc.)
   - Go 1.21+ (for building from source)

   ## Binary Installation
   ```bash
   # Download latest release
   wget https://github.com/.../perfcollector2-linux-amd64.tar.gz
   tar xzf perfcollector2-linux-amd64.tar.gz
   sudo mv bin/* /usr/local/bin/

   # Create config directory
   sudo mkdir -p /etc/perfcollector
   sudo cp config.example.yaml /etc/perfcollector/config.yaml

   # Edit config
   sudo nano /etc/perfcollector/config.yaml
   ```

   ## Configuration
   ```yaml
   xatbackend:
     url: https://portal.example.com
     api_key: your-api-key-here
     tenant_id: your-tenant-uuid

   collection:
     frequency: 60s
     mode: trickle  # or local

   machine:
     id: auto  # or specific: server01
   ```

   ## Systemd Service
   ```bash
   sudo systemctl enable perfcollector
   sudo systemctl start perfcollector
   sudo systemctl status perfcollector
   ```
   ```

2. **API Reference**:
   ```markdown
   # API Reference

   ## Authentication
   All API endpoints require Bearer token authentication:
   ```
   Authorization: Bearer <your-api-key>
   ```

   ## Endpoints

   ### POST /api/v1/performance/upload
   Upload performance data CSV.

   **Request**:
   ```http
   POST /api/v1/performance/upload HTTP/1.1
   Host: portal.example.com
   Authorization: Bearer abc123...
   Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

   ------WebKitFormBoundary
   Content-Disposition: form-data; name="file"; filename="perf_data.csv"
   Content-Type: text/csv

   timestamp,machine_id,cpu_user,...
   1704067200,server01,25.5,...
   ------WebKitFormBoundary
   Content-Disposition: form-data; name="machine_id"

   server01
   ------WebKitFormBoundary
   Content-Disposition: form-data; name="tenant_id"

   tenant-uuid-here
   ------WebKitFormBoundary--
   ```

   **Response (200 OK)**:
   ```json
   {
     "status": "success",
     "upload_id": "upload-uuid",
     "rows_imported": 5760,
     "machine_id": "server01",
     "timestamp_range": {
       "start": 1704067200,
       "end": 1704153600
     }
   }
   ```

   **Errors**:
   - 400: Invalid CSV format
   - 401: Invalid API key
   - 403: Tenant mismatch
   - 413: File too large
   - 500: Server error
   ```

3. **Troubleshooting Guide**:
   ```markdown
   # Troubleshooting

   ## perfcollector2 Issues

   ### Issue: Upload failing with "connection refused"
   **Symptoms**: `Error: dial tcp: connection refused`

   **Diagnosis**:
   ```bash
   # Check XATbackend URL
   curl -I https://portal.example.com/health

   # Check network connectivity
   ping portal.example.com
   ```

   **Solution**:
   - Verify XATbackend URL in config
   - Check firewall rules
   - Verify DNS resolution

   ### Issue: High memory usage
   **Symptoms**: pcc using >500MB RAM

   **Diagnosis**:
   ```bash
   ps aux | grep pcc
   pmap $(pgrep pcc)
   ```

   **Solution**:
   - Reduce buffer size in config
   - Increase flush frequency
   - Check for memory leaks (run with -memprofile)

   ## XATbackend Issues

   ### Issue: Upload endpoint returns 401
   **Symptoms**: API returns "Invalid API key"

   **Diagnosis**:
   ```bash
   # Test API key
   curl -X POST \
     -H "Authorization: Bearer ${API_KEY}" \
     https://portal.example.com/api/v1/auth/validate
   ```

   **Solution**:
   - Regenerate API key in portal
   - Check API key not expired
   - Verify correct tenant association
   ```

**Deliverables**:
- Complete documentation set (100+ pages)
- API reference with examples
- Troubleshooting guide
- Operations runbooks

**Acceptance Criteria**: Documentation reviewed and approved by all agents

**Milestone M7**: Infrastructure ready, deployment automated, documentation complete

---

## Phase 4: Launch (Weeks 10-12)

**Goal**: Deploy to production and stabilize

### Week 10: Beta Launch

#### 8.1 Beta Deployment (2 days)

**Agent**: DevOps Engineer

**Deployment Checklist**:
- [ ] Infrastructure provisioned (Azure)
- [ ] Database migrated
- [ ] Secrets configured (Key Vault)
- [ ] Monitoring enabled (Application Insights)
- [ ] SSL certificates installed
- [ ] DNS configured
- [ ] Health checks passing
- [ ] Backups configured

**Deployment Process**:
```bash
# 1. Run Terraform
cd terraform/
terraform plan
terraform apply

# 2. Deploy XATbackend
git push origin main  # Triggers GitHub Actions

# 3. Verify deployment
curl https://portal.perfanalysis.com/health
# Expected: {"status": "healthy"}

# 4. Create superuser
az webapp ssh --name perfanalysis-backend \
              --resource-group perfanalysis-rg \
              --command "python manage.py createsuperuser"

# 5. Smoke test
python scripts/smoke_test.py --env production
```

**Deliverables**:
- Production deployment successful
- Health checks passing
- Smoke tests passing

**Acceptance Criteria**: System accessible at production URL

#### 8.2 Beta User Onboarding (3 days)

**Agents**: Backend Python Developer + Automation Engineer

**Beta User Setup**:

1. **Create Beta Tenants**:
   ```python
   # management/commands/create_beta_tenants.py
   from django.core.management.base import BaseCommand
   from apps.tenants.models import Tenant, Domain

   class Command(BaseCommand):
       def handle(self, *args, **options):
           beta_tenants = [
               ('Beta Corp', 'betacorp'),
               ('Test Industries', 'testind'),
               ('Demo LLC', 'demo'),
           ]

           for name, subdomain in beta_tenants:
               tenant = Tenant.objects.create(
                   schema_name=subdomain,
                   name=name
               )
               Domain.objects.create(
                   domain=f'{subdomain}.perfanalysis.com',
                   tenant=tenant,
                   is_primary=True
               )
               self.stdout.write(f'✅ Created tenant: {name}')
   ```

2. **Register Test Machines**:
   ```bash
   # For each beta tenant
   for i in {1..3}; do
     # Install perfcollector2
     ssh beta-server-$i 'bash -s' < install_perfcollector.sh

     # Configure with API key
     ssh beta-server-$i "cat > /etc/perfcollector/config.yaml" <<EOF
   xatbackend:
     url: https://portal.perfanalysis.com
     api_key: $(get_api_key_for_machine $i)
     tenant_id: $(get_tenant_id)
   EOF

     # Start service
     ssh beta-server-$i 'systemctl start perfcollector'
   done
   ```

3. **Training Sessions**:
   - Session 1: Portal overview (1 hour)
   - Session 2: Machine registration (30 minutes)
   - Session 3: Report generation (30 minutes)
   - Q&A and troubleshooting (30 minutes)

**Deliverables**:
- 3 beta tenant accounts
- 10 machines registered and collecting data
- Training materials
- User feedback forms

**Acceptance Criteria**: Beta users successfully generating reports

#### 8.3 Monitoring & Alerting (3 days)

**Agent**: DevOps Engineer

**Application Insights Dashboards**:

1. **System Health Dashboard**:
   - Request rate (requests/min)
   - Response time (p50, p95, p99)
   - Error rate (%)
   - Availability (%)
   - Server resources (CPU, memory)

2. **Business Metrics Dashboard**:
   - Active tenants
   - Machines monitored
   - Data uploads (count, volume)
   - Reports generated
   - API key usage

**Alert Rules**:

```yaml
# alerts.yaml
alerts:
  - name: High Error Rate
    metric: requests/failed
    threshold: "> 5%"
    window: 5m
    severity: critical
    action: page_oncall

  - name: Slow Response Time
    metric: requests/duration
    threshold: "p95 > 2000ms"
    window: 10m
    severity: warning
    action: slack_notification

  - name: Database Connection Failure
    metric: database/connection_errors
    threshold: "> 0"
    window: 1m
    severity: critical
    action: page_oncall

  - name: Low Availability
    metric: availability
    threshold: "< 99%"
    window: 1h
    severity: high
    action: email_team
```

**Log Aggregation**:
```python
# settings.py
LOGGING = {
    'version': 1,
    'handlers': {
        'azure': {
            'class': 'opencensus.ext.azure.log_exporter.AzureLogHandler',
            'connection_string': os.getenv('APPLICATIONINSIGHTS_CONNECTION_STRING'),
        },
    },
    'loggers': {
        'django': {
            'handlers': ['azure'],
            'level': 'WARNING',
        },
        'apps': {
            'handlers': ['azure'],
            'level': 'INFO',
        },
    },
}
```

**Deliverables**:
- Application Insights dashboards
- Alert rules configured
- On-call rotation
- Incident response playbook

**Acceptance Criteria**: Full observability, alerts triggering correctly

#### 8.4 Beta Feedback Collection (2 days)

**Agents**: Integration Architect + Component Agents

**Feedback Mechanisms**:

1. **User Survey**:
   ```markdown
   # Beta User Feedback Survey

   ## Overall Experience (1-5 stars)
   - Ease of setup: ⭐⭐⭐⭐⭐
   - Portal usability: ⭐⭐⭐⭐⭐
   - Report usefulness: ⭐⭐⭐⭐⭐

   ## What worked well?
   [Free text]

   ## What needs improvement?
   [Free text]

   ## Feature requests:
   [Free text]

   ## Bugs encountered:
   [Free text]
   ```

2. **Bug Tracking**:
   ```yaml
   # GitHub Issues template
   name: Bug Report
   description: Report a bug in PerfAnalysis
   labels: ["bug", "beta"]
   body:
     - type: dropdown
       id: component
       attributes:
         label: Component
         options:
           - perfcollector2
           - XATbackend
           - automated-Reporting

     - type: textarea
       id: description
       attributes:
         label: Bug Description
         description: Detailed description of the bug

     - type: textarea
       id: steps
       attributes:
         label: Steps to Reproduce
         placeholder: |
           1. Go to...
           2. Click on...
           3. See error

     - type: textarea
       id: expected
       attributes:
         label: Expected Behavior

     - type: textarea
       id: actual
       attributes:
         label: Actual Behavior
   ```

3. **Feature Requests Backlog**:
   ```markdown
   # Feature Request Template

   **Title**: [Short description]

   **User Story**: As a [user type], I want [goal] so that [benefit].

   **Priority**: [Low/Medium/High/Critical]

   **Complexity**: [Small/Medium/Large]

   **Agent**: [Which agent would implement this]

   **Acceptance Criteria**:
   - [ ] Criterion 1
   - [ ] Criterion 2
   ```

**Deliverables**:
- User feedback survey
- Bug tracking system
- Feature request backlog
- Weekly feedback review meetings

**Acceptance Criteria**: Feedback process established, issues tracked

**Milestone M8**: Beta launch successful, users onboarded, monitoring operational, feedback collected

---

### Week 11: Stabilization

#### 9.1 Bug Triage (1 day)

**Agent**: Integration Architect

**Triage Process**:

```python
# Bug severity classification
severity_criteria = {
    'P0 - Critical': [
        'System down / unavailable',
        'Data loss',
        'Security vulnerability',
        'Multi-tenant data leak',
    ],
    'P1 - High': [
        'Major feature broken',
        'Performance degradation >50%',
        'Affecting >10% of users',
    ],
    'P2 - Medium': [
        'Minor feature broken',
        'Workaround available',
        'Affecting <10% of users',
    ],
    'P3 - Low': [
        'Cosmetic issue',
        'Nice-to-have enhancement',
        'Documentation error',
    ],
}

# Assignment rules
def assign_bug(bug):
    if 'perfcollector' in bug.component:
        return 'Go Backend Developer'
    elif 'xatbackend' in bug.component and 'tenant' in bug.tags:
        return 'Django Tenants Specialist'
    elif 'xatbackend' in bug.component:
        return 'Backend Python Developer'
    elif 'reporting' in bug.component:
        return 'R Performance Expert'
    elif 'integration' in bug.tags:
        return 'Integration Architect'
    elif 'security' in bug.tags:
        return 'Security Architect'
    else:
        return 'Integration Architect'  # Default triage
```

**Deliverables**:
- Triaged bug list
- Priority queue
- Agent assignments
- Fix timeline

**Acceptance Criteria**: All bugs classified and assigned

#### 9.2 Critical Bug Fixes (5 days)

**Agents**: Component-specific agents

**Bug Fix Process**:

1. **Reproduce bug**
2. **Write failing test**
3. **Implement fix**
4. **Verify test passes**
5. **Add regression test**
6. **Deploy hotfix**
7. **Verify in production**
8. **Update documentation**

**Example: Upload Timeout Bug**

**Bug Report**:
```
Title: CSV upload timing out for files >10MB
Severity: P1
Component: XATbackend
Agent: Backend Python Developer

Description: Uploads fail with 504 Gateway Timeout for CSV files >10MB
Steps to Reproduce:
1. Collect 24h of data (creates ~15MB CSV)
2. Upload via API
3. Request times out after 30s

Expected: Upload succeeds
Actual: 504 Gateway Timeout
```

**Fix**:
```python
# Before: Processing in request/response cycle
@require_api_key
def upload_performance_data(request):
    csv_file = request.FILES.get('file')
    # Parse and insert immediately (slow for large files)
    df = pd.read_csv(csv_file)
    for _, row in df.iterrows():
        PerformanceData.objects.create(...)  # One query per row!
    return JsonResponse({'status': 'success'})

# After: Async processing with Celery
from celery import shared_task

@shared_task
def process_uploaded_csv(file_path, machine_id):
    df = pd.read_csv(file_path)

    # Bulk insert
    objects = [
        PerformanceData(
            machine_id=machine_id,
            timestamp=row['timestamp'],
            # ... fields
        )
        for _, row in df.iterrows()
    ]

    PerformanceData.objects.bulk_create(objects, batch_size=1000)

    # Cleanup temp file
    os.remove(file_path)

@require_api_key
def upload_performance_data(request):
    csv_file = request.FILES.get('file')

    # Save to temp file
    temp_path = f'/tmp/upload_{uuid.uuid4()}.csv'
    with open(temp_path, 'wb') as f:
        for chunk in csv_file.chunks():
            f.write(chunk)

    # Queue for async processing
    task = process_uploaded_csv.delay(temp_path, machine_id)

    # Return immediately
    return JsonResponse({
        'status': 'processing',
        'task_id': task.id
    })
```

**Deliverables**:
- All P0 bugs fixed (0 remaining)
- All P1 bugs fixed (0 remaining)
- P2 bugs addressed (>80%)
- Hotfix deployments
- Regression tests added

**Acceptance Criteria**: No critical bugs in production

#### 9.3 Performance Tuning (4 days)

**Agents**: All performance-focused agents

**Production Performance Analysis**:

1. **Identify Bottlenecks**:
   - Application Insights query
   - Slow query log analysis
   - CPU/memory profiling

2. **Optimize**:
   - Database query optimization
   - Caching layer (Redis)
   - Code optimizations

3. **Measure Improvement**:
   - Before/after benchmarks
   - Production metrics comparison

**Example: Slow Dashboard Query**

**Issue**: Dashboard loading 10+ seconds

**Analysis**:
```sql
-- Slow query (8 seconds)
SELECT m.machine_id, m.name,
       COUNT(pd.id) as data_points,
       MAX(pd.timestamp) as last_update
FROM machines m
LEFT JOIN performance_data pd ON m.id = pd.machine_id
GROUP BY m.id
ORDER BY last_update DESC;
```

**Optimization**:
```python
# Add materialized view or denormalize
class Machine(models.Model):
    # ... existing fields
    last_data_timestamp = models.BigIntegerField(null=True)
    data_point_count = models.IntegerField(default=0)

    def update_stats(self):
        stats = self.performancedata_set.aggregate(
            last_ts=Max('timestamp'),
            count=Count('id')
        )
        self.last_data_timestamp = stats['last_ts']
        self.data_point_count = stats['count']
        self.save()

# Update stats on data upload
@receiver(post_save, sender=PerformanceData)
def update_machine_stats(sender, instance, created, **kwargs):
    if created:
        machine = instance.machine
        machine.data_point_count += 1
        machine.last_data_timestamp = max(
            machine.last_data_timestamp or 0,
            instance.timestamp
        )
        machine.save(update_fields=['data_point_count', 'last_data_timestamp'])

# Now dashboard query is fast (50ms)
machines = Machine.objects.all().order_by('-last_data_timestamp')
```

**Deliverables**:
- Performance analysis report
- Optimization implementations
- Benchmark results
- Updated documentation

**Acceptance Criteria**: All SLAs met (API p95 <200ms, report gen <30s)

**Milestone M9**: All critical bugs fixed, performance SLAs achieved, system stable

---

### Week 12: Production Launch

#### 10.1 Production Readiness Review (1 day)

**Agents**: Solutions Architect + Integration Architect + Security Architect

**Go/No-Go Checklist**:

```markdown
# Production Readiness Checklist

## Functionality
- [x] All core features working
- [x] End-to-end workflows tested
- [x] API endpoints functional
- [x] Report generation working

## Performance
- [x] Upload API: p95 < 200ms
- [x] Query API: p95 < 100ms
- [x] Report generation: < 30s for 24h data
- [x] System handles 100 concurrent users

## Security
- [x] Security audit completed
- [x] All critical/high vulnerabilities resolved
- [x] Multi-tenant isolation validated
- [x] API keys secured
- [x] Secrets in Key Vault

## Operations
- [x] Monitoring dashboards configured
- [x] Alerts set up and tested
- [x] Backups configured (7-day retention)
- [x] Disaster recovery plan documented
- [x] On-call rotation established

## Documentation
- [x] User guides complete
- [x] API documentation complete
- [x] Operations runbooks complete
- [x] Troubleshooting guides complete

## Testing
- [x] Unit tests >80% coverage
- [x] Integration tests passing
- [x] Performance tests passing
- [x] Security tests passing
- [x] Beta testing completed

## Deployment
- [x] Production infrastructure ready
- [x] Automated deployment working
- [x] Rollback procedures tested
- [x] Blue-green deployment configured

## Compliance
- [x] Privacy policy reviewed
- [x] Terms of service reviewed
- [x] Data retention policy defined
- [x] GDPR compliance (if applicable)

## Risk Assessment
- [ ] Critical risks mitigated
- [ ] Rollback plan ready
- [ ] Support escalation defined

DECISION: [ ] GO  [ ] NO-GO

If NO-GO, blockers:
1. [List blocking issues]
```

**Deliverables**:
- Completed readiness checklist
- Risk assessment
- Go/No-Go decision
- Launch communication plan

**Acceptance Criteria**: Approved for production launch

#### 10.2 Production Deployment (1 day)

**Agent**: DevOps Engineer

**Launch Day Procedure**:

```bash
#!/bin/bash
# production_launch.sh

set -e

echo "=== PerfAnalysis Production Launch ==="
echo "Date: $(date)"
echo "Version: $(git describe --tags)"

# Pre-launch checks
echo "[1/10] Running pre-launch checks..."
python scripts/pre_launch_check.py || exit 1

# Backup current production (if exists)
echo "[2/10] Creating backup..."
az postgres flexible-server backup create \
  --resource-group perfanalysis-rg \
  --name perfanalysis-db \
  --backup-name pre-launch-$(date +%Y%m%d)

# Deploy to staging slot
echo "[3/10] Deploying to staging slot..."
git push azure-staging main

# Wait for staging deployment
echo "[4/10] Waiting for staging deployment..."
sleep 60

# Run smoke tests on staging
echo "[5/10] Running smoke tests on staging..."
python scripts/smoke_test.py --env staging || {
    echo "❌ Smoke tests failed on staging"
    exit 1
}

# Swap staging to production
echo "[6/10] Swapping staging to production..."
az webapp deployment slot swap \
  --name perfanalysis-backend \
  --resource-group perfanalysis-rg \
  --slot staging \
  --target-slot production

# Wait for swap
sleep 30

# Health check
echo "[7/10] Running health checks..."
for i in {1..20}; do
    status=$(curl -s -o /dev/null -w "%{http_code}" \
             https://portal.perfanalysis.com/health)
    if [ $status -eq 200 ]; then
        echo "✅ Health check passed"
        break
    fi
    if [ $i -eq 20 ]; then
        echo "❌ Health check failed, rolling back..."
        # Rollback
        az webapp deployment slot swap \
          --name perfanalysis-backend \
          --resource-group perfanalysis-rg \
          --slot production \
          --target-slot staging
        exit 1
    fi
    echo "Waiting for health check... ($i/20)"
    sleep 5
done

# Run full smoke tests
echo "[8/10] Running production smoke tests..."
python scripts/smoke_test.py --env production || {
    echo "❌ Production smoke tests failed"
    # Alert team but don't auto-rollback
}

# Update DNS (if needed)
echo "[9/10] Updating DNS..."
# (Already configured via Terraform)

# Send launch notification
echo "[10/10] Sending launch notification..."
python scripts/notify_launch.py

echo "=== ✅ Production Launch Complete ==="
echo "URL: https://portal.perfanalysis.com"
echo "Status: $(curl -s https://portal.perfanalysis.com/health | jq -r .status)"
```

**Deliverables**:
- Production cutover executed
- DNS updated
- SSL certificates verified
- All services operational

**Acceptance Criteria**: System live at production URL, health checks passing

#### 10.3 Post-Launch Support (3 days)

**Agents**: All agents on-call rotation

**War Room Schedule** (72 hours):

| Time | Agent(s) on Duty | Responsibilities |
|------|------------------|------------------|
| Day 1: 00:00-08:00 | DevOps + Integration Architect | Monitor metrics, respond to alerts |
| Day 1: 08:00-16:00 | All component agents | Active monitoring, bug fixes |
| Day 1: 16:00-24:00 | DevOps + Security Architect | Monitor metrics, security watch |
| Day 2: 00:00-24:00 | Rotating shift | Continued monitoring |
| Day 3: 00:00-24:00 | Rotating shift | Continued monitoring |

**Monitoring Dashboard** (live during launch):

```markdown
# Launch Dashboard (Auto-refresh 30s)

## System Health
- Status: 🟢 HEALTHY
- Uptime: 99.98%
- Error Rate: 0.02%

## Traffic
- Requests/min: 120
- Active users: 45
- Active tenants: 12

## Performance
- API Response (p95): 187ms ✅
- Report Generation: 24s ✅
- Database CPU: 35% ✅

## Recent Events
- 14:23:15 - Upload spike: 150 req/min (auto-scaled) ✅
- 14:15:03 - New tenant registered ✅
- 14:00:00 - Scheduled backup completed ✅

## Alerts (Last 1h)
- None 🎉

## Action Items
- [ ] None at this time
```

**Incident Response**:

```markdown
# Incident Response Procedure

## Severity Levels
- **SEV-1 (Critical)**: System down, data loss, security breach
  - Response time: Immediate
  - Escalation: Page entire team

- **SEV-2 (High)**: Major feature broken, performance degraded
  - Response time: 15 minutes
  - Escalation: Alert on-call agent

- **SEV-3 (Medium)**: Minor feature issue
  - Response time: 1 hour
  - Escalation: Slack notification

## Response Steps
1. Acknowledge alert
2. Assess severity
3. Communicate to team
4. Investigate root cause
5. Implement fix or rollback
6. Verify resolution
7. Post-mortem (for SEV-1/SEV-2)
```

**Deliverables**:
- 72-hour monitoring completed
- Incident response tested
- No critical issues
- Team handoff to operations

**Acceptance Criteria**: System stable for 72 hours, <2 SEV-2 incidents, 0 SEV-1 incidents

#### 10.4 Knowledge Transfer (5 days)

**Agents**: All component agents

**Training Sessions**:

1. **Day 1: Architecture Overview** (Solutions Architect + Integration Architect)
   - System architecture
   - Component responsibilities
   - Data flows
   - Integration points
   - Q&A

2. **Day 2: Component Deep Dives** (Component agents)
   - Session A: perfcollector2 (Go Backend Developer)
   - Session B: XATbackend (Backend Python Developer + Django Tenants Specialist)
   - Session C: automated-Reporting (R Performance Expert)

3. **Day 3: Operations** (DevOps Engineer)
   - Deployment procedures
   - Monitoring and alerting
   - Backup and restore
   - Incident response

4. **Day 4: Troubleshooting** (Integration Architect)
   - Common issues
   - Debugging techniques
   - Log analysis
   - Performance troubleshooting

5. **Day 5: Hands-On Lab** (All agents)
   - Deploy a hotfix
   - Onboard a new tenant
   - Generate a report
   - Respond to simulated incident

**Handoff Documentation**:

```markdown
# Operations Handoff

## Daily Operations
- Review monitoring dashboards (30 min/day)
- Check for failed uploads (automated alerts)
- Verify report generation (automated)
- Review user feedback

## Weekly Operations
- Review database growth (scaling plan)
- Security patch updates
- Performance analysis
- User support queue

## Monthly Operations
- Backup testing (restore drill)
- Security audit
- Capacity planning review
- Feature backlog prioritization

## Emergency Contacts
- On-call rotation: [PagerDuty link]
- Escalation: [Team lead]
- Vendor support: [Azure support]

## Runbooks
1. [Deployment Procedure](runbooks/deployment.md)
2. [Rollback Procedure](runbooks/rollback.md)
3. [Incident Response](runbooks/incident-response.md)
4. [Backup/Restore](runbooks/backup-restore.md)
5. [Scaling Procedure](runbooks/scaling.md)
```

**Deliverables**:
- Training materials
- Video recordings of sessions
- Hands-on lab guide
- Handoff documentation
- Operations team certified

**Acceptance Criteria**: Operations team independently handles 2 incidents without escalation

**Milestone M10**: Production launch successful, system stable, knowledge transfer complete

---

## Success Metrics

### Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Availability** | 99.9% | Application Insights uptime |
| **Data Collection Uptime** | >99% | perfcollector2 systemd status |
| **Upload Success Rate** | >99.5% | XATbackend logs |
| **API Response Time (p95)** | <200ms | Application Insights |
| **Report Generation Time** | <30s for 24h data | R execution time |
| **Database Query Time (p95)** | <100ms | PostgreSQL slow query log |
| **Error Rate** | <1% | Application Insights |
| **Test Coverage** | >80% | Code coverage reports |
| **Security Vulnerabilities** | 0 critical/high | Security scans |

### Business Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Tenants Onboarded** | 10+ | Database count |
| **Machines Monitored** | 100+ | Active machines |
| **Reports Generated** | 1000+/month | Report count |
| **Data Points Collected** | 10M+/month | PerformanceData rows |
| **User Satisfaction** | >4.5/5 | User surveys |
| **Time to Onboard Machine** | <10 minutes | Timed user flow |
| **Support Tickets** | <5/week | Ticket system |
| **System Cost** | <$500/month | Azure billing |

### Quality Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Code Quality Score** | A | SonarQube/CodeClimate |
| **Documentation Coverage** | 100% | Doc checklist |
| **Bug Density** | <5 bugs/1000 LOC | GitHub Issues |
| **Mean Time to Repair** | <4 hours | Incident logs |
| **Deployment Frequency** | Daily (non-breaking) | GitHub Actions |
| **Rollback Rate** | <5% | Deployment logs |

---

## Risk Management

### High Risks

| Risk | Impact | Probability | Mitigation | Owner |
|------|--------|-------------|------------|-------|
| **Integration data format mismatch** | High | Medium | Early integration testing, contract validation, automated tests | Integration Architect |
| **Multi-tenant data leak** | Critical | Low | Extensive security testing, code reviews, penetration testing | Security Architect + Django Tenants Specialist |
| **Performance degradation at scale** | High | Medium | Load testing, performance monitoring, horizontal scaling plan | All performance agents |
| **Azure deployment failure** | High | Low | Staging environment, blue-green deployment, rollback procedures | DevOps Engineer |
| **Go binary platform incompatibility** | Medium | Medium | Multi-platform CI builds, pre-compiled binaries for common platforms | Go Backend Developer |

### Medium Risks

| Risk | Impact | Probability | Mitigation | Owner |
|------|--------|-------------|------------|-------|
| **R package dependency conflicts** | Medium | Medium | renv for reproducible environments, version pinning | R Performance Expert |
| **PostgreSQL schema migration failure** | Medium | Low | Migration testing, backup before migrations, rollback plan | Data Architect |
| **API key compromise** | High | Low | Key rotation procedures, rate limiting, audit logging | Security Architect |
| **Insufficient documentation** | Medium | Medium | Documentation sprints, peer reviews, user testing | All agents |
| **Team member unavailability** | Medium | Low | Cross-training, documentation, agent framework for knowledge | Integration Architect |

### Low Risks

| Risk | Impact | Probability | Mitigation | Owner |
|------|--------|-------------|------------|-------|
| **Third-party package vulnerabilities** | Low | Medium | Dependabot, regular updates, security scanning | DevOps Engineer |
| **Timezone handling bugs** | Low | Medium | UTC everywhere, comprehensive timezone tests | All developers |
| **Browser compatibility issues** | Low | Low | Modern browser support only, cross-browser testing | Backend Python Developer |

---

## Resource Allocation

### Agent Effort by Phase

| Phase | Weeks | Primary Agents | Effort Distribution |
|-------|-------|----------------|---------------------|
| **Foundation** | 1-3 | DevOps (30%), Go Dev (25%), Python Dev (25%), R Expert (20%) | 100% |
| **Integration** | 4-6 | Integration Architect (40%), Security Architect (30%), All Dev Agents (30%) | 100% |
| **Production Prep** | 7-9 | Security Architect (30%), DevOps (30%), Performance Agents (40%) | 100% |
| **Launch** | 10-12 | DevOps (40%), Integration Architect (30%), Support rotation (30%) | 100% |

### Component Ownership

| Component | Primary Agent | Supporting Agents | Backup |
|-----------|---------------|-------------------|--------|
| **perfcollector2** | Go Backend Developer | Linux Systems Engineer, Configuration Management Specialist | Integration Architect |
| **XATbackend** | Backend Python Developer | Django Tenants Specialist, Security Architect | Integration Architect |
| **automated-Reporting** | R Performance Expert | Data Architect, Time-Series Architect | Data Quality Engineer |
| **Integration** | Integration Architect | API Architect, Security Architect | Solutions Architect |
| **Deployment** | DevOps Engineer | Solutions Architect, Automation Engineer | Integration Architect |

### Parallel Work Streams

Throughout the 12 weeks, multiple work streams proceed in parallel:

**Stream 1: perfcollector2** (Go Backend Developer + Linux Systems Engineer)
- Weeks 1-3: Core development
- Weeks 4-6: Integration with XATbackend
- Weeks 7-9: Optimization and hardening
- Weeks 10-12: Production support

**Stream 2: XATbackend** (Backend Python Developer + Django Tenants Specialist)
- Weeks 1-3: Core development
- Weeks 4-6: Integration endpoints
- Weeks 7-9: Security hardening and performance
- Weeks 10-12: Production support

**Stream 3: automated-Reporting** (R Performance Expert + Data Architect)
- Weeks 1-3: Parameterization and optimization
- Weeks 4-6: Integration with XATbackend exports
- Weeks 7-9: Performance tuning
- Weeks 10-12: Production support

**Stream 4: Integration** (Integration Architect coordinating all)
- Weeks 1-12: Continuous coordination
- Weeks 4-6: Focus on integration testing
- Weeks 7-9: End-to-end validation
- Weeks 10-12: Launch coordination

---

## Dependencies & Prerequisites

### External Dependencies

| Dependency | Version | Purpose | Risk |
|------------|---------|---------|------|
| **Azure Subscription** | N/A | Cloud infrastructure | Low - available |
| **GitHub** | N/A | Code hosting, CI/CD | Low - SLA 99.9% |
| **PostgreSQL** | 12.2+ | Database backend | Low - mature |
| **R** | 4.5.2+ | Report generation | Low - stable |
| **Go** | 1.21+ | perfcollector2 | Low - stable |
| **Python** | 3.10+ | XATbackend | Low - stable |

### Internal Prerequisites

| Prerequisite | Status | Blocking For | Due Date |
|--------------|--------|--------------|----------|
| **Agent framework** | ✅ Complete | All development | Week 0 |
| **Documentation** | ✅ Complete | All development | Week 0 |
| **Git repositories** | ✅ Setup | All development | Week 0 |
| **Development environments** | Pending | Week 2 development | Week 1 |
| **CI/CD pipelines** | Pending | All commits | Week 1 |
| **Azure account** | Pending | Week 9 deployment | Week 7 |

---

## Post-Launch Roadmap (Months 4-6)

### Phase 5: Enhancement & Scale

**Month 4: Oracle Migration**

**Agents**: Oracle Developer + Data Architect + Time-Series Architect

**Goals**:
- Migrate from PostgreSQL to Oracle 26ai Free
- Implement time-series partitioning
- Add vector search capabilities (future ML features)

**Tasks**:
1. **Oracle Setup**:
   - Install Oracle 26ai Free (Docker or native)
   - Configure connectivity from XATbackend
   - Test Oracle client (ROracle / DBI)

2. **Schema Migration**:
   - Convert PostgreSQL DDL to Oracle
   - Implement time-series partitioning by day
   - Create materialized views for aggregations

3. **Data Migration**:
   - Export PostgreSQL data
   - Transform to Oracle format
   - Bulk load to Oracle
   - Validate data integrity

4. **Application Updates**:
   - Update Django models for Oracle
   - Update R queries for Oracle syntax
   - Performance testing

**Deliverables**:
- Oracle database operational
- Data migrated
- Application using Oracle
- Performance benchmarks

**Success Criteria**: Oracle performance >= PostgreSQL, zero data loss

---

**Month 5: Advanced Features**

**Agents**: Backend Python Developer + R Performance Expert + Data Scientist

**Real-Time Dashboards**:
- WebSocket integration for live metrics
- Real-time charts (Chart.js / D3.js)
- Streaming data updates

**Anomaly Detection**:
- Statistical models for baseline calculation
- Alerting on anomalies
- Machine learning integration (future)

**Multi-Machine Comparison**:
- Side-by-side machine comparison
- Fleet-wide dashboards
- Trend analysis across machines

**Deliverables**:
- Real-time dashboard
- Anomaly detection system
- Multi-machine reports

**Success Criteria**: Real-time updates <5s latency, anomaly detection >90% accuracy

---

**Month 6: Scale & Optimization**

**Agents**: DevOps Engineer + Solutions Architect + All Performance Agents

**Multi-Region Deployment**:
- Deploy to West US (primary: East US)
- Cross-region database replication
- Geo-routing with Azure Front Door

**Horizontal Scaling**:
- Auto-scaling App Service
- Database read replicas
- Redis caching layer

**Cost Optimization**:
- Right-size resources
- Reserved instances
- Spot instances for batch processing

**Deliverables**:
- Multi-region deployment
- Auto-scaling configured
- Cost reduced by 30%

**Success Criteria**: 99.99% availability, <$350/month operational cost

---

## Conclusion

This 12-week development plan delivers the complete PerfAnalysis integrated performance monitoring ecosystem through agent-driven development.

**Key Success Factors**:
1. ✅ **Agent-First Workflow**: Every task handled by specialized experts
2. ✅ **Parallel Development**: 3 components developed simultaneously
3. ✅ **Continuous Integration**: E2E testing from Week 4
4. ✅ **Security First**: Hardening in Week 7 (not an afterthought)
5. ✅ **Beta Testing**: Real user feedback before launch
6. ✅ **Phased Rollout**: Staging → Beta → Production
7. ✅ **Knowledge Transfer**: Ops team fully trained

**Timeline Summary**:
- **Weeks 1-3**: Foundation & Component Development
- **Weeks 4-6**: Integration & E2E Testing
- **Weeks 7-9**: Security, Performance, Deployment Prep
- **Weeks 10-12**: Beta Launch → Production Launch → Stabilization

**Final Deliverables**:
- ✅ 3 integrated components (perfcollector2, XATbackend, automated-Reporting)
- ✅ Production deployment on Azure
- ✅ 100+ machines monitored
- ✅ 10+ tenants onboarded
- ✅ Complete documentation
- ✅ Trained operations team

**Ready to Begin**: Week 1, Task 1.1 - Development Environment Setup

---

**Next Steps**:
1. Review and approve this plan
2. Kick off Week 1 with DevOps Engineer
3. Daily standups with agent assignments
4. Weekly milestone reviews
5. Adjust as needed based on learnings

Let's build PerfAnalysis! 🚀
