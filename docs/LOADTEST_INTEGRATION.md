# LoadTest Integration Guide

## Overview

The LoadTest feature provides standardized CPU performance benchmarking across the PerfAnalysis ecosystem, enabling price-performance comparisons between different servers, VMs, and cloud providers.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          LoadTest Data Flow                             │
└─────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
  │  perfcollector2  │      │  XATSimplified   │      │  perf-dashboard  │
  │                  │      │                  │      │                  │
  │ ┌──────────────┐ │      │ ┌──────────────┐ │      │ ┌──────────────┐ │
  │ │perfcpumeasure│ │      │ │LoadTestResult│ │      │ │LoadTestChart │ │
  │ │    (CLI)     │ │      │ │   (Model)    │ │      │ │ (Component)  │ │
  │ └──────────────┘ │      │ └──────────────┘ │      │ └──────────────┘ │
  │        │         │      │        ▲         │      │        ▲         │
  │        ▼         │      │        │         │      │        │         │
  │ ┌──────────────┐ │      │ ┌──────────────┐ │      │ ┌──────────────┐ │
  │ │ pcd daemon   │◄┼──────┼►│  Run API     │◄┼──────┼─│LoadTestHistory│ │
  │ │/v1/loadtest  │ │      │ │/run/<id>/    │ │      │ │   (Page)     │ │
  │ └──────────────┘ │      │ └──────────────┘ │      │ └──────────────┘ │
  │                  │      │        │         │      │        │         │
  └──────────────────┘      │        ▼         │      │        ▼         │
                            │ ┌──────────────┐ │      │ ┌──────────────┐ │
                            │ │ Compare API  │◄┼──────┼─│LoadTestCompare│ │
                            │ │/compare/     │ │      │ │   (Page)     │ │
                            │ └──────────────┘ │      │ └──────────────┘ │
                            │                  │      │                  │
                            └──────────────────┘      └──────────────────┘
```

## Components

### 1. perfcollector2 (Go)

**Location**: `perfcollector2/`

#### perfcpumeasure CLI
Standalone CPU benchmark tool that measures "work units" at different CPU utilization levels.

```bash
# Run benchmark and output JSON
./bin/perfcpumeasure -v -o results.json -format json

# Output formats: json, csv, jsonl
./bin/perfcpumeasure -format csv -o benchmark.csv
```

**Work Unit**: A standardized CPU operation:
- 512KB memory array traversal
- 17 iterations of CPU spin per element
- Read-Modify-Write operations with XOR

#### pcd Daemon API
Remote LoadTest execution via HTTP.

```bash
# Start pcd with API key
echo "your-api-key-here" > ~/.pcd/apikeys
PCD_LOGLEVEL=info LISTENADDRESS=0.0.0.0:8080 ./bin/pcd

# Trigger LoadTest remotely
curl -X POST \
  -H "apikey: your-api-key-here" \
  -H "Content-Type: application/json" \
  http://server:8080/v1/loadtest
```

**Response**:
```json
{
  "hostname": "server-01",
  "timestamp": 1705320000,
  "numCores": 8,
  "results": [
    {"busyPct": 10, "workUnits": 1200},
    {"busyPct": 20, "workUnits": 2400},
    ...
    {"busyPct": 100, "workUnits": 12000}
  ],
  "maxUnits": 12000,
  "avgUnits": 6600,
  "unitsPerSec": 1500.0
}
```

### 2. XATSimplified (Django)

**Location**: `XATSimplified/`

#### LoadTestResult Model
Stores benchmark results with per-utilization breakdown.

```python
class LoadTestResult(models.Model):
    collector = ForeignKey(Collector)
    units_10pct = PositiveIntegerField()
    units_20pct = PositiveIntegerField()
    # ... through units_100pct
    created_at = DateTimeField()
```

#### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/loadtests/` | GET | List all LoadTest results |
| `/api/v1/loadtests/<id>/` | GET | Get specific result |
| `/api/v1/loadtests/run/<collector_id>/` | POST | Run test on remote server |
| `/api/v1/loadtests/compare/` | GET/POST | Compare multiple servers |

#### Price-Performance Calculation
```python
price_performance = max_work_units / hourly_cost
# Higher = better value
```

### 3. perf-dashboard (React)

**Location**: `perf-dashboard/`

#### Pages

- **LoadTestHistory** (`/loadtest-history`): Browse all results, run new tests
- **LoadTestComparison** (`/loadtest`): Compare up to 4 servers visually

#### Chart Types

1. **Line Chart**: Performance curves across utilization levels
2. **Bar Chart**: Work units at each CPU percentage
3. **Difference Chart**: Gap analysis between baseline and others
4. **Table View**: Statistics and CSV export

## Usage Workflow

### 1. Run LoadTest on Server

**Option A: Direct CLI**
```bash
cd /path/to/perfcollector2
./bin/perfcpumeasure -v -o results.json
```

**Option B: Via pcd Daemon**
1. Start pcd on target server
2. Use perf-dashboard "Run LoadTest" button
3. Results automatically stored in database

### 2. Compare Servers

1. Navigate to perf-dashboard LoadTestComparison page
2. Select 2-4 collectors to compare
3. View performance curves and price-performance metrics
4. Toggle chart types (line/bar/difference/table)

### 3. Price-Performance Analysis

1. Ensure `hourly_cost` is set on Collector model
2. Click price-performance toggle (💰) in comparison view
3. Servers ranked by work units per dollar per hour

## Configuration

### Collector Setup for Remote LoadTest

```python
# In XATSimplified admin or API
collector = Collector.objects.create(
    name="aws-m5-xlarge",
    pcd_address="10.0.1.5:8080",
    pcd_apikey="secure-api-key-here",
    hourly_cost=Decimal("0.192"),  # USD/hour
    vcpus=4,
    memory_gib=Decimal("16"),
    vm_brand="aws"
)
```

### Environment Variables

**pcd Daemon**:
```bash
LISTENADDRESS=0.0.0.0:8080   # Listen address
PCD_LOGLEVEL=info            # Log level: trace, debug, info, warn, error
```

## Troubleshooting

### LoadTest Times Out

The pcd daemon has a 2-minute timeout. For slow servers:
- Reduce CPU count or check for resource contention
- Ensure no other heavy processes running during test

### Missing Price-Performance Data

1. Check `hourly_cost` is set on Collector
2. Verify cost is greater than 0
3. Ensure LoadTest has non-zero work units

### No Data in Dashboard

1. Verify XATSimplified API is accessible
2. Check authentication token is valid
3. Confirm LoadTestResult records exist in database

## Sample Data Generation

For testing without real servers:

```bash
cd XATSimplified
python generate_loadtest_data.py
```

Creates 8 realistic server profiles with 3 test runs each.

## Integration Testing

```bash
# Full integration test
cd XATSimplified
./test_api.sh

# Specific LoadTest tests
curl -X GET "http://localhost:8001/api/v1/loadtests/" \
  -H "Authorization: Bearer $TOKEN"

curl -X POST "http://localhost:8001/api/v1/loadtests/compare/" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"collector_ids": ["uuid-1", "uuid-2"]}'
```

## Related Documentation

- [perfcollector2 README](../perfcollector2/README.md)
- [XATSimplified API Documentation](../XATSimplified/README.md)
- [perf-dashboard User Guide](../perf-dashboard/README.md)
