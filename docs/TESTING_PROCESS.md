# Performance Testing Process Document

This document describes the end-to-end workflow for collecting, processing, and visualizing performance data using the PerfAnalysis ecosystem.

---

## ⚠️ CRITICAL: Pre-Flight Verification Required

**BEFORE running ANY load test on ANY system, you MUST verify that pcc is actively collecting data.**

### The Problem

The `pcc` binary defaults to **trickle mode** (streaming to a server) when `PCC_MODE` is not explicitly set. This causes the error:

```
NewClient: must set api key
```

If you see this error, **your collection has failed** and no data is being recorded.

### The Solution

**ALWAYS** set `PCC_MODE=local` explicitly when collecting to a local file:

```bash
# CORRECT - Explicit local mode
PCC_MODE=local \
PCC_DURATION=10m \
PCC_FREQUENCY=1s \
PCC_COLLECTION=~/loadtest.json \
./pcc

# WRONG - Will default to trickle mode and fail
PCC_DURATION=10m \
PCC_FREQUENCY=1s \
PCC_COLLECTION=~/loadtest.json \
./pcc
```

### Mandatory Verification Steps

Before starting ANY load test:

1. **Start pcc with explicit `PCC_MODE=local`**
2. **Wait 5 seconds** for initialization
3. **Verify the process is running**: `ps aux | grep pcc`
4. **Verify the collection file exists**: `ls -la ~/loadtest.json`
5. **Verify the file has data**: `wc -l ~/loadtest.json` (should show > 0 lines)
6. **Only then start your load test**

If ANY verification step fails, **STOP** and troubleshoot before proceeding.

### Automated Verification Script

Use the universal load test script at `scripts/run_loadtest.sh` which includes automatic pre-flight verification:

```bash
# Copy to target system and run
scp scripts/run_loadtest.sh user@target:~/
ssh user@target
./run_loadtest.sh 10  # 10-minute test with automatic verification
```

The script will **automatically abort** if pcc is not collecting properly.

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

**⚠️ CRITICAL: You MUST set `PCC_MODE=local` explicitly!**

**On Target System:**

```bash
# CORRECT: Collect for 10 minutes at 1-second intervals with explicit local mode
PCC_MODE=local \
PCC_DURATION=10m \
PCC_FREQUENCY=1s \
PCC_COLLECTION=~/loadtest.json \
./pcc

# CORRECT: With explicit environment variables
export PCC_MODE=local
export PCC_DURATION=1h
export PCC_FREQUENCY=15s
export PCC_COLLECTION=~/hourly-collection.json
./pcc
```

**Verify collection is working before starting load tests:**

```bash
# After starting pcc, wait 5 seconds then verify:
sleep 5
ls -la ~/loadtest.json           # File should exist
wc -l ~/loadtest.json            # Should show > 0 lines
ps aux | grep pcc                 # Process should be running
```

**Environment Variables:**

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `PCC_MODE` | Collection mode | `local` (file) or `trickle` (server) | **YES - Always set to `local` for file collection** |
| `PCC_DURATION` | How long to collect | `10m`, `1h`, `24h` | Yes |
| `PCC_FREQUENCY` | Sampling interval | `1s`, `5s`, `15s` | Yes |
| `PCC_COLLECTION` | Output JSON file path | `~/loadtest.json` | Yes (for local mode) |

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
| **"NewClient: must set api key"** | **PCC_MODE not set to `local`** | **Add `PCC_MODE=local` to pcc command** |
| Empty collection file | pcc failed silently | Check pcc log file, verify PCC_MODE=local |
| No data in dashboard | Time range filtering | Click "ALL" button |
| 302 redirects on API | Not authenticated | Log in via browser first |
| Empty charts | No data imported | Verify import completed |
| Stale data after edit | Container not restarted | `docker compose restart xatbackend` |

### 7.4 Troubleshooting pcc Collection Failures

**Symptom**: `NewClient: must set api key` error

**Root Cause**: The `pcc` binary defaults to trickle mode (streaming to a server) when `PCC_MODE` is not explicitly set. Without an API key, the trickle connection fails.

**Solution**:
```bash
# Always set PCC_MODE=local for file-based collection
PCC_MODE=local \
PCC_DURATION=10m \
PCC_FREQUENCY=1s \
PCC_COLLECTION=~/loadtest.json \
./pcc
```

**Symptom**: Collection file exists but is empty

**Root Cause**: pcc process died or failed to initialize

**Solution**:
1. Check the pcc log file for errors
2. Verify pcc process is running: `ps aux | grep pcc`
3. Ensure sufficient disk space
4. Check file permissions

**Symptom**: Missing metrics in collection

**Root Cause**: pcc started AFTER load test began

**Solution**: Always use the pre-flight verification workflow:
1. Start pcc first
2. Wait for verification (file exists, has data)
3. Only then start load test

---

## Complete Workflow Example

### Test: Azure VM Benchmark

```bash
# === LOCAL MACHINE: Build and deploy ===
cd ~/projects/PerfCollector2/perfcollector2
GOOS=linux GOARCH=amd64 go build -o bin/pcc-linux ./cmd/pcc
scp bin/pcc-linux azureuser@pcc-test-vm.eastus.cloudapp.azure.com:~/pcc

# === TARGET SYSTEM: Start collection with verification ===
ssh azureuser@pcc-test-vm.eastus.cloudapp.azure.com
chmod +x ~/pcc

# Start pcc with EXPLICIT local mode (CRITICAL!)
PCC_MODE=local \
PCC_DURATION=10m \
PCC_FREQUENCY=1s \
PCC_COLLECTION=~/benchmark.json \
./pcc &

# MANDATORY: Wait and verify collection is working
sleep 5
if [ ! -f ~/benchmark.json ]; then
    echo "ERROR: Collection file not created! Check pcc output."
    exit 1
fi
if [ $(wc -l < ~/benchmark.json) -eq 0 ]; then
    echo "ERROR: Collection file is empty! pcc may have failed."
    exit 1
fi
echo "SUCCESS: pcc is collecting data. Starting load test..."

# Now safe to start your load test
sysbench cpu --threads=2 --time=600 run

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

### Alternative: Using the Universal Load Test Script

For automated testing with built-in verification, use the provided script:

```bash
# === LOCAL MACHINE: Deploy script and binaries ===
scp scripts/run_loadtest.sh azureuser@target-vm:~/
scp bin/pcc-linux azureuser@target-vm:~/
scp bin/pcc-container-linux azureuser@target-vm:~/

# === TARGET SYSTEM: Run automated test ===
ssh azureuser@target-vm
chmod +x ~/run_loadtest.sh ~/pcc-linux ~/pcc-container-linux

# Run 10-minute test with automatic verification
./run_loadtest.sh 10

# Script will:
# 1. Verify binaries exist
# 2. Start pcc collectors
# 3. VERIFY collectors are working (abort if not)
# 4. Run load tests
# 5. Collect results
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
- [run_loadtest.sh](../scripts/run_loadtest.sh) - Universal load test script with pre-flight verification
