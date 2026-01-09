# Performance Testing Process Document

This document describes the end-to-end workflow for collecting, processing, and visualizing performance data using the PerfAnalysis ecosystem.

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           LOCAL MACHINE (macOS)                              │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     Docker Compose Environment                       │    │
│  │                                                                      │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │    │
│  │  │  PostgreSQL  │  │  XATbackend  │  │     pcd      │              │    │
│  │  │   :5432      │◄─┤   :8000      │  │   :8080      │              │    │
│  │  │              │  │   (Django)   │  │  (Receiver)  │              │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘              │    │
│  │         ▲                 ▲                 ▲                       │    │
│  └─────────┼─────────────────┼─────────────────┼───────────────────────┘    │
│            │                 │                 │                             │
│            │                 │                 │ HTTP POST                   │
│            │                 │                 │ (Trickle Mode)              │
│    ┌───────┴───────┐  ┌──────┴──────┐         │                             │
│    │   psql        │  │  Browser    │         │                             │
│    │   queries     │  │  Dashboard  │         │                             │
│    └───────────────┘  └─────────────┘         │                             │
│                                                │                             │
│    ┌───────────────────────────────────────────┼───────────────────────┐    │
│    │                    pcprocess               │                       │    │
│    │              (JSON → CSV conversion)       │                       │    │
│    │                                            │                       │    │
│    │   Input: .json collection file             │                       │    │
│    │   Output: .csv performance metrics         │                       │    │
│    └────────────────────────────────────────────┼───────────────────────┘    │
│                                                 │                             │
└─────────────────────────────────────────────────┼─────────────────────────────┘
                                                  │
                                                  │ SSH + SCP
                                                  │
┌─────────────────────────────────────────────────┼─────────────────────────────┐
│                      TARGET SYSTEM (Azure/OCI VM)                             │
│                                                 │                             │
│    ┌────────────────────────────────────────────┴───────────────────────┐    │
│    │                           pcc (collector)                           │    │
│    │                                                                     │    │
│    │   Reads from /proc filesystem:                                      │    │
│    │   • /proc/stat      → CPU metrics                                   │    │
│    │   • /proc/meminfo   → Memory metrics                                │    │
│    │   • /proc/diskstats → Disk I/O metrics                              │    │
│    │   • /proc/net/dev   → Network metrics                               │    │
│    │   • /proc/cpuinfo   → CPU info (cores, model)                       │    │
│    │                                                                     │    │
│    │   Output Modes:                                                     │    │
│    │   • Local: Saves to JSON file                                       │    │
│    │   • Trickle: Streams to pcd server via HTTP                         │    │
│    └─────────────────────────────────────────────────────────────────────┘    │
│                                                                               │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Target System Setup

### 1.1 Deploy pcc Binary to Target

**On Local Machine:**

```bash
# Build pcc for Linux
cd /Users/danmcdougal/projects/PerfCollector2/perfcollector2
GOOS=linux GOARCH=amd64 go build -o bin/pcc-linux ./cmd/pcc

# Copy to target system
scp bin/pcc-linux azureuser@<target-ip>:~/pcc
```

### 1.2 Configure Target System

**On Target System (via SSH):**

```bash
ssh azureuser@<target-ip>

# Make pcc executable
chmod +x ~/pcc

# Verify it works
./pcc --help
```

---

## Phase 2: Data Collection

### 2.1 Local Mode (Standalone Collection)

Collects metrics and saves to a local JSON file.

**On Target System:**

```bash
# Collect for 10 minutes at 1-second intervals
PCC_DURATION=10m \
PCC_FREQUENCY=1s \
PCC_COLLECTION=~/loadtest.json \
./pcc

# Or with explicit environment file
export PCC_DURATION=1h
export PCC_FREQUENCY=15s
export PCC_COLLECTION=~/hourly-collection.json
./pcc
```

**Environment Variables:**

| Variable | Description | Example |
|----------|-------------|---------|
| `PCC_DURATION` | How long to collect | `10m`, `1h`, `24h` |
| `PCC_FREQUENCY` | Sampling interval | `1s`, `5s`, `15s` |
| `PCC_COLLECTION` | Output JSON file path | `~/loadtest.json` |

### 2.2 Trickle Mode (Real-time Streaming)

Streams metrics directly to pcd server.

**On Target System:**

```bash
# Stream to pcd server running on local machine
PCC_MODE=trickle \
PCC_DURATION=10m \
PCC_FREQUENCY=1s \
PCC_SERVER=<local-machine-ip>:8080 \
PCC_APIKEY=<api-key> \
./pcc
```

**On Local Machine (Docker):**

```bash
# pcd is already running in Docker
docker compose logs -f pcd
```

---

## Phase 3: Data Transfer (Local Mode Only)

### 3.1 Copy Collection File to Local Machine

**On Local Machine:**

```bash
# Create results directory
mkdir -p ~/projects/PerfAnalysis/results/<test-name>

# Copy JSON collection from target
scp azureuser@<target-ip>:~/loadtest.json \
    ~/projects/PerfAnalysis/results/<test-name>/
```

---

## Phase 4: Data Processing

### 4.1 Convert JSON to CSV

**On Local Machine:**

```bash
cd /Users/danmcdougal/projects/PerfCollector2/perfcollector2

# Process the collection
PCR_COLLECTION=~/projects/PerfAnalysis/results/<test-name>/loadtest.json \
PCR_OUTDIR=~/projects/PerfAnalysis/results/<test-name>/csv \
./bin/pcprocess
```

**Output Files Generated:**

```
results/<test-name>/csv/
├── host.csv           # Host-level metrics (CPU, memory, disk, network)
├── containers.csv     # Container metrics (if containers detected)
└── container_names.json  # Container ID to name mapping
```

### 4.2 CSV Column Reference

**host.csv columns:**

| Column | Description | Unit |
|--------|-------------|------|
| `timestamp` | Collection time | ISO 8601 |
| `cpu_user` | User CPU time | % |
| `cpu_system` | System CPU time | % |
| `cpu_iowait` | I/O wait time | % |
| `cpu_idle` | Idle time | % |
| `cpu_steal` | Stolen time (VM) | % |
| `mem_total` | Total memory | MB |
| `mem_used` | Used memory | MB |
| `mem_available` | Available memory | MB |
| `mem_buffers` | Buffer memory | MB |
| `mem_cached` | Cached memory | MB |
| `disk_read_bytes` | Disk read throughput | bytes/s |
| `disk_write_bytes` | Disk write throughput | bytes/s |
| `disk_read_ops` | Disk read IOPS | ops/s |
| `disk_write_ops` | Disk write IOPS | ops/s |
| `net_rx_bytes` | Network receive | bytes/s |
| `net_tx_bytes` | Network transmit | bytes/s |
| `net_rx_packets` | Packets received | pkt/s |
| `net_tx_packets` | Packets transmitted | pkt/s |

---

## Phase 5: Data Import to Dashboard

### 5.1 Import via Django Management Command

**On Local Machine:**

```bash
# Import CSV to database
docker compose exec xatbackend python manage.py import_performance \
    --file /app/results/<test-name>/csv/host.csv \
    --collector-name "test-vm-01" \
    --site-name "Azure Benchmark"
```

### 5.2 Import via Portal Upload (Future)

```bash
# Upload via API (when implemented)
curl -X POST \
    -H "Authorization: Bearer <api-key>" \
    -F "file=@results/<test-name>/csv/host.csv" \
    -F "machine_id=test-vm-01" \
    http://localhost:8000/api/v1/performance/upload
```

---

## Phase 6: Data Visualization

### 6.1 Access Dashboard

**On Local Machine:**

1. Open browser to: http://localhost:8000
2. Log in with credentials
3. Navigate to Collectors list
4. Select the collector to view

### 6.2 Dashboard Features

**Time Range Controls:**

| Button | Description |
|--------|-------------|
| `ALL` | Show complete collection (default) |
| `1H` | Last hour of the collection |
| `6H` | Last 6 hours of the collection |
| `24H` | Last 24 hours of the collection |
| `7D` | Last 7 days of the collection |

**Note:** Time ranges are calculated relative to the collection's data, NOT the current time. This ensures historical collections remain viewable indefinitely.

**Available Views:**

- **Overview**: Summary charts for CPU, Memory, Disk, Network
- **Host Utilization**: Detailed breakdown with per-component charts
- **Utilization Tables**: Percentile statistics (P50, P90, P95, P99)
- **Compare**: Side-by-side comparison of multiple collectors

---

## Phase 7: Verification & Troubleshooting

### 7.1 Verify Data in Database

```bash
# Check collector exists
docker compose exec postgres psql -U perfadmin -d perfanalysis -c \
    "SELECT id, machinename, sitename FROM collectors_collector;"

# Check data time range
docker compose exec postgres psql -U perfadmin -d perfanalysis -c \
    "SELECT collector_id, MIN(timestamp), MAX(timestamp), COUNT(*)
     FROM dashboard_performancemetric
     GROUP BY collector_id;"

# Sample data points
docker compose exec postgres psql -U perfadmin -d perfanalysis -c \
    "SELECT timestamp, cpu_user, mem_used
     FROM dashboard_performancemetric
     WHERE collector_id = <id>
     ORDER BY timestamp
     LIMIT 10;"
```

### 7.2 Check Docker Services

```bash
# Service status
docker compose ps

# View logs
docker compose logs xatbackend --tail=50
docker compose logs postgres --tail=50

# Restart services after code changes
docker compose down && docker compose up -d
```

### 7.3 Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| No data in dashboard | Time range filtering | Click "ALL" button |
| 302 redirects on API | Not authenticated | Log in via browser first |
| Empty charts | No data imported | Verify import completed |
| Stale data after edit | Container not restarted | `docker compose restart xatbackend` |

---

## Complete Workflow Example

### Test: Azure VM Benchmark

```bash
# === LOCAL MACHINE: Build and deploy ===
cd ~/projects/PerfCollector2/perfcollector2
GOOS=linux GOARCH=amd64 go build -o bin/pcc-linux ./cmd/pcc
scp bin/pcc-linux azureuser@pcc-test-vm.eastus.cloudapp.azure.com:~/pcc

# === TARGET SYSTEM: Run collection ===
ssh azureuser@pcc-test-vm.eastus.cloudapp.azure.com
chmod +x ~/pcc
PCC_DURATION=10m PCC_FREQUENCY=1s PCC_COLLECTION=~/benchmark.json ./pcc

# === LOCAL MACHINE: Retrieve and process ===
mkdir -p ~/projects/PerfAnalysis/Azure/results/benchmark
scp azureuser@pcc-test-vm.eastus.cloudapp.azure.com:~/benchmark.json \
    ~/projects/PerfAnalysis/Azure/results/benchmark/

cd ~/projects/PerfCollector2/perfcollector2
PCR_COLLECTION=~/projects/PerfAnalysis/Azure/results/benchmark/benchmark.json \
PCR_OUTDIR=~/projects/PerfAnalysis/Azure/results/benchmark/csv \
./bin/pcprocess

# === LOCAL MACHINE: Import to dashboard ===
cd ~/projects/PerfAnalysis
docker compose exec xatbackend python manage.py import_performance \
    --file /app/Azure/results/benchmark/csv/host.csv \
    --collector-name "pcc-test-vm" \
    --site-name "Azure Benchmark"

# === LOCAL MACHINE: View in browser ===
open http://localhost:8000/dashboard/
```

---

## Data Retention

| Storage | Location | Retention |
|---------|----------|-----------|
| Raw JSON | Target system `~/` | Manual cleanup |
| Processed CSV | Local `results/` | Manual cleanup |
| Database | Docker volume `postgres_data` | Persistent |
| Dashboard | Browser | Real-time from DB |

---

## Security Considerations

- API keys stored in pcd at `~/.pcd/apikeys`
- Database credentials in `docker-compose.yml` (dev only)
- SSH keys for target system access
- No secrets in JSON/CSV files

---

## Related Documentation

- [README.md](../README.md) - Project overview
- [CLAUDE.md](../CLAUDE.md) - Agent-based development guide
- [USER_GUIDE.md](../USER_GUIDE.md) - User documentation
- [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) - Production deployment
