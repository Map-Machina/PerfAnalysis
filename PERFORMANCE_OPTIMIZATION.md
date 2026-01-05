# Performance Optimization Guide

Comprehensive guide for optimizing PerfAnalysis system performance across all components.

## Table of Contents

1. [Overview](#overview)
2. [perfcollector2 Optimization (Go)](#perfcollector2-optimization-go)
3. [XATbackend Optimization (Django)](#xatbackend-optimization-django)
4. [automated-Reporting Optimization (R)](#automated-reporting-optimization-r)
5. [Database Optimization](#database-optimization)
6. [Infrastructure Optimization](#infrastructure-optimization)
7. [Monitoring & Profiling](#monitoring--profiling)
8. [Performance Benchmarks](#performance-benchmarks)

---

## Overview

### Performance Goals

| Component | Metric | Target | Current |
|-----------|--------|--------|---------|
| perfcollector2 | Collection latency | <100ms | TBD |
| perfcollector2 | CPU usage | <5% | TBD |
| perfcollector2 | Memory usage | <50MB | TBD |
| XATbackend | API response time (p95) | <500ms | TBD |
| XATbackend | Upload processing | <2s/file | TBD |
| XATbackend | Concurrent users | >100 | TBD |
| PostgreSQL | Query time (p95) | <100ms | TBD |
| R Reports | Generation time | <30s | TBD |
| System | Overall throughput | >1000 metrics/s | TBD |

### Performance Testing Strategy

```bash
# Run benchmarks
cd tests/performance
go test -bench=. -benchmem benchmark_test.go

# Run load tests
python load_test.py --scenario light
python load_test.py --scenario medium
python load_test.py --scenario heavy

# Run integration tests
cd tests/integration
pytest test_e2e_data_flow.py -v
```

---

## perfcollector2 Optimization (Go)

### 1. Efficient /proc Parsing

**Problem**: Parsing /proc files on every collection creates overhead.

**Solution**: Use buffered I/O and efficient parsing.

```go
// GOOD: Efficient parsing with reused buffers
type Parser struct {
    buf []byte  // Reuse buffer
}

func (p *Parser) ParseCPUStat(path string) (*CPUStat, error) {
    // Reuse buffer to avoid allocations
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, err
    }

    // Parse efficiently using bytes package
    lines := bytes.Split(data, []byte("\n"))
    // ... parse lines
}

// BAD: Creates new buffer each time
func ParseCPUStat(path string) (*CPUStat, error) {
    data, _ := os.ReadFile(path)
    str := string(data)  // Unnecessary allocation
    lines := strings.Split(str, "\n")
    // ...
}
```

**Optimization Checklist**:
- ✅ Reuse buffers for file reads
- ✅ Use `bytes` package instead of `strings` when possible
- ✅ Avoid unnecessary string conversions
- ✅ Use `strconv.ParseUint` instead of `fmt.Sscanf`
- ✅ Pre-allocate slices with known capacity

### 2. Concurrent Collection

**Problem**: Sequential collection of multiple metrics is slow.

**Solution**: Collect metrics concurrently with worker pools.

```go
// GOOD: Concurrent collection
func (c *Collector) CollectAll() (*Metrics, error) {
    var wg sync.WaitGroup
    results := make(chan *MetricResult, 6)

    collectors := []func() (*MetricResult, error){
        c.collectCPU,
        c.collectMemory,
        c.collectDisk,
        c.collectNetwork,
        c.collectFilesystem,
        c.collectProcesses,
    }

    for _, collect := range collectors {
        wg.Add(1)
        go func(fn func() (*MetricResult, error)) {
            defer wg.Done()
            result, err := fn()
            if err != nil {
                // Log error, continue with other metrics
                return
            }
            results <- result
        }(collect)
    }

    go func() {
        wg.Wait()
        close(results)
    }()

    // Aggregate results
    metrics := &Metrics{}
    for result := range results {
        metrics.Add(result)
    }

    return metrics, nil
}
```

**Optimization Checklist**:
- ✅ Use goroutines for independent metric collection
- ✅ Limit concurrency with worker pools (avoid goroutine explosion)
- ✅ Use channels for communication
- ✅ Handle errors gracefully (don't fail entire collection)

### 3. Memory Management

**Problem**: Frequent allocations cause GC pressure.

**Solution**: Use object pools and pre-allocation.

```go
// GOOD: Object pooling
var metricPool = sync.Pool{
    New: func() interface{} {
        return &Metrics{
            CPUStats:  make([]CPUStat, 0, 16),
            DiskStats: make([]DiskStat, 0, 8),
        }
    },
}

func CollectMetrics() *Metrics {
    m := metricPool.Get().(*Metrics)
    defer metricPool.Put(m)

    // Use m...
    return m
}
```

**Optimization Checklist**:
- ✅ Use `sync.Pool` for frequently allocated objects
- ✅ Pre-allocate slices with expected capacity
- ✅ Reuse buffers across collection cycles
- ✅ Profile with `go tool pprof` to find allocations

### 4. API Optimization

**Problem**: JSON marshaling overhead on every request.

**Solution**: Use efficient encoding and response caching.

```go
// GOOD: Efficient JSON encoding
func (h *Handler) ServeMetrics(w http.ResponseWriter, r *http.Request) {
    metrics := h.collector.GetLatest()

    w.Header().Set("Content-Type", "application/json")

    // Encode directly to response writer (no intermediate buffer)
    enc := json.NewEncoder(w)
    if err := enc.Encode(metrics); err != nil {
        http.Error(w, err.Error(), http.StatusInternalServerError)
        return
    }
}

// Consider: Use easyjson or ffjson for even faster marshaling
```

**Optimization Checklist**:
- ✅ Use `json.Encoder` directly to `http.ResponseWriter`
- ✅ Consider faster JSON libraries (easyjson, ffjson)
- ✅ Enable HTTP compression (gzip)
- ✅ Implement caching for frequently requested data
- ✅ Use connection pooling for HTTP clients

### 5. Configuration

**Production Configuration**:

```bash
# Environment variables for optimal performance
PCD_COLLECTION_INTERVAL=60  # Seconds between collections
PCD_WORKER_POOL_SIZE=10     # Concurrent collection workers
PCD_API_PORT=8080
PCD_API_READ_TIMEOUT=10
PCD_API_WRITE_TIMEOUT=10
PCD_MAX_CONCURRENT_REQUESTS=100
GOMAXPROCS=0  # Use all CPU cores
```

---

## XATbackend Optimization (Django)

### 1. Database Query Optimization

**Problem**: N+1 queries and missing indexes.

**Solution**: Use `select_related`, `prefetch_related`, and proper indexing.

```python
# GOOD: Optimized query
def get_collectors_with_data(user):
    return Collector.objects.filter(owner=user).select_related(
        'platform'
    ).prefetch_related(
        'files'  # CollectedData related_name
    ).only(
        'pk', 'machinename', 'sitename', 'platform__name'
    )

# BAD: N+1 queries
def get_collectors_with_data(user):
    collectors = Collector.objects.filter(owner=user)
    for collector in collectors:
        platform = collector.platform  # N queries
        files = collector.files.all()  # N queries
```

**Optimization Checklist**:
- ✅ Use `select_related` for ForeignKey relationships
- ✅ Use `prefetch_related` for ManyToMany and reverse ForeignKey
- ✅ Use `only()` to fetch specific fields
- ✅ Add database indexes (see Database Optimization)
- ✅ Use Django Debug Toolbar to identify N+1 queries

### 2. View Optimization

**Problem**: Slow view rendering and processing.

**Solution**: Use caching, pagination, and async processing.

```python
from django.core.cache import cache
from django.core.paginator import Paginator
from django.views.decorators.cache import cache_page

# GOOD: Cached view
@login_required
@cache_page(60)  # Cache for 60 seconds
def collector_list(request):
    collectors = get_collectors_with_data(request.user)

    # Paginate results
    paginator = Paginator(collectors, 25)
    page = request.GET.get('page', 1)
    collectors_page = paginator.get_page(page)

    return render(request, 'collectors/list.html', {
        'collectors': collectors_page
    })

# GOOD: Async file processing
from django.core.files.uploadedfile import UploadedFile
from celery import shared_task

@shared_task
def process_uploaded_file(file_id):
    """Process uploaded file asynchronously."""
    data = CollectedData.objects.get(pk=file_id)
    # Heavy processing here...

@login_required
def upload_file(request, collector_id):
    if request.method == 'POST':
        form = DataUploadForm(request.POST, request.FILES)
        if form.is_valid():
            data = form.save()
            # Process asynchronously
            process_uploaded_file.delay(data.pk)
            return redirect('collectors:manage')
```

**Optimization Checklist**:
- ✅ Use caching for expensive views
- ✅ Implement pagination for large datasets
- ✅ Move heavy processing to Celery tasks
- ✅ Use async views for I/O-bound operations (Django 3.1+)
- ✅ Minimize template complexity

### 3. File Upload Optimization

**Problem**: Large file uploads block server.

**Solution**: Stream uploads and use background processing.

```python
# settings.py
FILE_UPLOAD_MAX_MEMORY_SIZE = 5242880  # 5MB - larger files go to disk
DATA_UPLOAD_MAX_MEMORY_SIZE = 10485760  # 10MB

# Use streaming for large files
class StreamingUploadView(View):
    def post(self, request, *args, **kwargs):
        if request.FILES.get('file'):
            file = request.FILES['file']

            # Stream to storage
            with default_storage.open(f'uploads/{file.name}', 'wb') as dest:
                for chunk in file.chunks():
                    dest.write(chunk)
```

**Optimization Checklist**:
- ✅ Use chunked uploads for large files
- ✅ Store files on disk, not in memory
- ✅ Process files asynchronously
- ✅ Validate file types before upload
- ✅ Use CDN for static files

### 4. Multi-Tenant Optimization

**Problem**: Schema switching overhead.

**Solution**: Optimize tenant resolution and caching.

```python
# GOOD: Cache tenant resolution
from django.core.cache import cache

class TenantMiddleware:
    def __call__(self, request):
        hostname = request.get_host().split(':')[0]

        # Cache tenant lookup
        cache_key = f'tenant:{hostname}'
        tenant = cache.get(cache_key)

        if tenant is None:
            tenant = get_tenant_model().objects.get(
                domain__domain=hostname
            )
            cache.set(cache_key, tenant, 3600)  # 1 hour

        connection.set_tenant(tenant)
        request.tenant = tenant
```

**Optimization Checklist**:
- ✅ Cache tenant resolution
- ✅ Use connection pooling
- ✅ Minimize schema switches
- ✅ Pre-create tenant schemas

### 5. Configuration

**Production Configuration**:

```python
# settings.py

# Database connection pooling
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'CONN_MAX_AGE': 600,  # Connection pooling
        'OPTIONS': {
            'connect_timeout': 10,
            'options': '-c statement_timeout=30000',  # 30s query timeout
        },
    }
}

# Cache configuration
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://localhost:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        },
        'KEY_PREFIX': 'perfanalysis',
        'TIMEOUT': 300,
    }
}

# Session configuration
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'

# Static files
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'

# Security
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# Performance
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.gzip.GZipMiddleware',  # Enable compression
    'django.middleware.cache.UpdateCacheMiddleware',  # Cache middleware
    # ... other middleware
    'django.middleware.cache.FetchFromCacheMiddleware',
]
```

---

## Database Optimization

### 1. Indexing Strategy

```sql
-- Essential indexes for XATbackend

-- Collectors app
CREATE INDEX idx_collector_owner ON collectors_collector(owner_id);
CREATE INDEX idx_collector_machine ON collectors_collector(machinename);
CREATE INDEX idx_collector_site ON collectors_collector(sitename);
CREATE INDEX idx_collector_composite ON collectors_collector(owner_id, sitename, machinename);

-- CollectedData
CREATE INDEX idx_data_collector ON collectors_collecteddata(collector_id);
CREATE INDEX idx_data_upload_date ON collectors_collecteddata(upload_date);
CREATE INDEX idx_data_composite ON collectors_collecteddata(collector_id, upload_date DESC);

-- Analysis app
CREATE INDEX idx_analysis_collector ON analysis_captureanalysis(collector_id);
CREATE INDEX idx_analysis_status ON analysis_captureanalysis(status);
CREATE INDEX idx_analysis_created ON analysis_captureanalysis(created_at);

-- Multi-tenant
CREATE INDEX idx_domain_tenant ON partners_domain(tenant_id);
```

### 2. Query Optimization

```sql
-- Analyze query performance
EXPLAIN ANALYZE
SELECT c.*, p.name, COUNT(cd.id) as file_count
FROM collectors_collector c
LEFT JOIN collectors_platform p ON c.platform_id = p.id
LEFT JOIN collectors_collecteddata cd ON cd.collector_id = c.id
WHERE c.owner_id = 123
GROUP BY c.id, p.name
ORDER BY c.machinename;

-- Vacuum and analyze regularly
VACUUM ANALYZE collectors_collector;
VACUUM ANALYZE collectors_collecteddata;
```

### 3. Partitioning (for large datasets)

```sql
-- Partition CollectedData by upload date
CREATE TABLE collectors_collecteddata_2024_01 PARTITION OF collectors_collecteddata
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE collectors_collecteddata_2024_02 PARTITION OF collectors_collecteddata
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
```

### 4. Configuration

```bash
# postgresql.conf optimizations

# Memory settings
shared_buffers = 256MB                  # 25% of RAM
effective_cache_size = 1GB              # 50-75% of RAM
work_mem = 8MB                          # Per operation
maintenance_work_mem = 64MB             # For maintenance operations

# Checkpoints
checkpoint_completion_target = 0.9
wal_buffers = 16MB
max_wal_size = 1GB
min_wal_size = 80MB

# Planner
random_page_cost = 1.1                  # For SSD
effective_io_concurrency = 200          # For SSD

# Connections
max_connections = 100
```

---

## automated-Reporting Optimization (R)

### 1. Efficient Data Loading

```r
# GOOD: Efficient data loading
library(data.table)

load_performance_data <- function(file_path) {
  # Use data.table for fast reading
  dt <- fread(file_path)

  # Convert timestamp efficiently
  dt[, timestamp := as.POSIXct(timestamp, origin="1970-01-01")]

  return(dt)
}

# BAD: Slow data loading
load_performance_data_slow <- function(file_path) {
  df <- read.csv(file_path)  # Slow
  df$timestamp <- as.POSIXct(df$timestamp, origin="1970-01-01")
  return(df)
}
```

### 2. Visualization Optimization

```r
# GOOD: Optimized plotting
library(ggplot2)

create_cpu_plot <- function(data) {
  # Sample large datasets
  if (nrow(data) > 10000) {
    data <- data[seq(1, nrow(data), length.out = 10000), ]
  }

  ggplot(data, aes(x = timestamp, y = cpu_usage)) +
    geom_line() +
    theme_minimal() +
    labs(title = "CPU Usage Over Time")
}
```

### 3. Parallel Processing

```r
# Use parallel processing for multiple reports
library(parallel)

generate_reports <- function(collectors) {
  # Detect cores
  num_cores <- detectCores() - 1
  cl <- makeCluster(num_cores)

  # Export functions to cluster
  clusterExport(cl, c("generate_single_report", "load_performance_data"))

  # Process in parallel
  reports <- parLapply(cl, collectors, generate_single_report)

  stopCluster(cl)
  return(reports)
}
```

---

## Infrastructure Optimization

### 1. Docker Optimization

```dockerfile
# perfcollector2 - Multi-stage build
FROM golang:1.24-alpine AS builder
RUN apk add --no-cache git make gcc musl-dev
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o pcd ./cmd/pcd

FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=builder /build/pcd /app/pcd
CMD ["/app/pcd"]
```

### 2. Resource Limits

```yaml
# docker-compose.yml
services:
  xatbackend:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G

  postgres:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

---

## Monitoring & Profiling

### 1. Go Profiling

```bash
# CPU profiling
go test -cpuprofile=cpu.prof -bench=.
go tool pprof cpu.prof

# Memory profiling
go test -memprofile=mem.prof -bench=.
go tool pprof mem.prof

# Live profiling
curl http://localhost:8080/debug/pprof/profile?seconds=30 > cpu.prof
```

### 2. Django Profiling

```python
# Install django-silk
pip install django-silk

# Add to INSTALLED_APPS
INSTALLED_APPS = [
    # ...
    'silk',
]

# Add to MIDDLEWARE
MIDDLEWARE = [
    'silk.middleware.SilkyMiddleware',
    # ...
]

# Access profiling at /silk/
```

### 3. Database Profiling

```sql
-- Enable slow query logging
ALTER DATABASE perfanalysis SET log_min_duration_statement = 100;

-- View slow queries
SELECT * FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

---

## Performance Benchmarks

### Baseline Targets

| Component | Operation | Target | Acceptable |
|-----------|-----------|--------|------------|
| perfcollector2 | /proc/stat parse | <10ms | <50ms |
| perfcollector2 | Full collection | <100ms | <500ms |
| perfcollector2 | API response | <50ms | <200ms |
| XATbackend | Collector list | <100ms | <500ms |
| XATbackend | File upload (10MB) | <2s | <5s |
| XATbackend | Database query | <50ms | <200ms |
| PostgreSQL | INSERT | <10ms | <50ms |
| PostgreSQL | SELECT (indexed) | <10ms | <50ms |
| R Reports | Load 1M rows | <5s | <15s |
| R Reports | Generate plot | <2s | <10s |

### Running Benchmarks

```bash
# perfcollector2 benchmarks
cd perfcollector2
go test -bench=. -benchmem ./...

# XATbackend load tests
cd tests/performance
python load_test.py --scenario medium

# Integration tests
cd tests/integration
pytest test_e2e_data_flow.py --benchmark
```

---

## Summary

### Quick Wins

1. **Add database indexes** - Immediate query speedup
2. **Enable connection pooling** - Reduce connection overhead
3. **Implement caching** - Cache expensive queries
4. **Use pagination** - Limit data transfer
5. **Enable compression** - Reduce bandwidth

### Long-term Improvements

1. **Implement Celery** - Async task processing
2. **Add Redis** - Fast caching layer
3. **Set up CDN** - Static file delivery
4. **Database partitioning** - Handle large datasets
5. **Horizontal scaling** - Multiple app servers

### Monitoring

```bash
# Set up continuous monitoring
docker-compose exec xatbackend python manage.py check --deploy
docker-compose exec postgres pg_stat_statements_reset
docker stats
```
