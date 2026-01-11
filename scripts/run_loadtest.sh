#!/bin/bash
#
# Universal Load Test Script for PerfAnalysis
#
# This script ensures pcc collection is verified BEFORE starting load tests.
# It will ABORT if collection fails to start properly - NO EXCEPTIONS.
#
# Usage: ./run_loadtest.sh [duration_minutes]
#
# Prerequisites:
#   - pcc-linux (or pcc) binary in home directory or PATH
#   - sysbench installed on host
#   - Optional: pcc-container-linux for container metrics
#   - Optional: Docker containers with sysbench installed
#
# Environment Variables:
#   PCC_BINARY          - Path to pcc binary (default: ~/pcc-linux or ~/pcc)
#   PCC_CONTAINER_BINARY - Path to container pcc (default: ~/pcc-container-linux)
#   SKIP_CONTAINERS     - Set to "true" to skip container collection
#   SYSBENCH_THREADS    - Number of threads for host sysbench (default: 2)
#

set -e  # Exit on any error

#############################################
# CONFIGURATION
#############################################
DURATION_MINUTES=${1:-10}
DURATION_SECONDS=$((DURATION_MINUTES * 60))
PCC_BUFFER_SECONDS=30
FREQUENCY="5s"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR=~/results/$TIMESTAMP
SYSBENCH_THREADS=${SYSBENCH_THREADS:-2}

# Find pcc binary
if [ -n "$PCC_BINARY" ] && [ -x "$PCC_BINARY" ]; then
    PCC_BIN="$PCC_BINARY"
elif [ -x ~/pcc-linux ]; then
    PCC_BIN=~/pcc-linux
elif [ -x ~/pcc ]; then
    PCC_BIN=~/pcc
elif command -v pcc &> /dev/null; then
    PCC_BIN=$(command -v pcc)
else
    PCC_BIN=""
fi

# Find container pcc binary
if [ -n "$PCC_CONTAINER_BINARY" ] && [ -x "$PCC_CONTAINER_BINARY" ]; then
    PCC_CONTAINER_BIN="$PCC_CONTAINER_BINARY"
elif [ -x ~/pcc-container-linux ]; then
    PCC_CONTAINER_BIN=~/pcc-container-linux
elif [ -x ~/pcc-container ]; then
    PCC_CONTAINER_BIN=~/pcc-container
else
    PCC_CONTAINER_BIN=""
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#############################################
# FUNCTIONS
#############################################

abort_test() {
    echo ""
    echo -e "${RED}============================================================${NC}"
    echo -e "${RED}TEST ABORTED: $1${NC}"
    echo -e "${RED}============================================================${NC}"
    echo ""
    echo "No test was run. Fix the issue above and try again."

    # Cleanup any started processes
    [ -n "$HOST_PCC_PID" ] && kill $HOST_PCC_PID 2>/dev/null || true
    [ -n "$CONTAINER_PCC_PID" ] && kill $CONTAINER_PCC_PID 2>/dev/null || true

    exit 1
}

verify_pcc_collecting() {
    local pid=$1
    local collection_file=$2
    local name=$3
    local log_file=$4
    local wait_seconds=${5:-5}

    echo "  Verifying $name collection..."

    # Wait for collection to start
    sleep $wait_seconds

    # Check process is still running
    if ! ps -p $pid > /dev/null 2>&1; then
        echo -e "${RED}  ✗ $name pcc process died!${NC}"
        echo ""
        echo "Log contents:"
        cat "$log_file" 2>/dev/null || echo "(no log file)"
        return 1
    fi

    # Check collection file exists
    if [ ! -f "$collection_file" ]; then
        echo -e "${RED}  ✗ $name collection file not created!${NC}"
        echo ""
        echo "Expected: $collection_file"
        echo "Log contents:"
        cat "$log_file" 2>/dev/null || echo "(no log file)"
        return 1
    fi

    # Check collection file has data
    local line_count=$(wc -l < "$collection_file" 2>/dev/null || echo 0)
    if [ "$line_count" -eq 0 ]; then
        echo -e "${RED}  ✗ $name collection file is empty!${NC}"
        echo ""
        echo "Log contents:"
        cat "$log_file" 2>/dev/null || echo "(no log file)"
        return 1
    fi

    echo -e "${GREEN}  ✓ $name pcc verified (PID: $pid, $line_count samples)${NC}"
    return 0
}

#############################################
# MAIN SCRIPT
#############################################

echo ""
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}       PerfAnalysis Universal Load Test Script${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""
echo "Duration:    ${DURATION_MINUTES} minutes (${DURATION_SECONDS} seconds)"
echo "Timestamp:   ${TIMESTAMP}"
echo "Results:     ${RESULTS_DIR}"
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

#############################################
# PHASE 1: PRE-FLIGHT CHECKS
#############################################
echo -e "${YELLOW}━━━ PHASE 1: Pre-flight Checks ━━━${NC}"
echo ""

# Check for pcc binary - THIS IS REQUIRED
if [ -z "$PCC_BIN" ]; then
    abort_test "pcc binary not found! Install pcc-linux to ~/pcc-linux"
fi
echo -e "${GREEN}  ✓ pcc binary: $PCC_BIN${NC}"

# Check for sysbench
if ! command -v sysbench &> /dev/null; then
    abort_test "sysbench not installed! Run: apt-get install sysbench"
fi
echo -e "${GREEN}  ✓ sysbench installed${NC}"

# Check for container pcc (optional)
if [ -n "$PCC_CONTAINER_BIN" ] && [ "$SKIP_CONTAINERS" != "true" ]; then
    echo -e "${GREEN}  ✓ container pcc: $PCC_CONTAINER_BIN${NC}"
    COLLECT_CONTAINERS=true

    # Check for running containers
    if command -v docker &> /dev/null; then
        CONTAINER_COUNT=$(sudo docker ps -q 2>/dev/null | wc -l || echo 0)
        if [ "$CONTAINER_COUNT" -gt 0 ]; then
            echo -e "${GREEN}  ✓ Found ${CONTAINER_COUNT} running containers${NC}"
        else
            echo -e "${YELLOW}  ⚠ No running containers found${NC}"
            COLLECT_CONTAINERS=false
        fi
    else
        echo -e "${YELLOW}  ⚠ Docker not available${NC}"
        COLLECT_CONTAINERS=false
    fi
else
    COLLECT_CONTAINERS=false
    echo -e "${YELLOW}  ⚠ Container collection disabled${NC}"
fi

echo ""

#############################################
# PHASE 2: START PCC COLLECTORS
#############################################
echo -e "${YELLOW}━━━ PHASE 2: Starting PCC Collectors ━━━${NC}"
echo ""

# Kill any existing pcc processes
echo "  Stopping any existing pcc processes..."
pkill -f "pcc-linux" 2>/dev/null || true
pkill -f "pcc-container" 2>/dev/null || true
pkill -f "pcc$" 2>/dev/null || true
sleep 2

# Calculate total collection duration
PCC_DURATION=$((DURATION_SECONDS + PCC_BUFFER_SECONDS))

# ================================================================
# START HOST PCC - CRITICAL: MUST USE PCC_MODE=local
# ================================================================
echo "  Starting HOST pcc collector..."
echo "    Mode: local (REQUIRED - do not use trickle without API key)"
echo "    Duration: ${PCC_DURATION}s"
echo "    Frequency: ${FREQUENCY}"
echo "    Output: ${RESULTS_DIR}/host_collection.json"

PCC_MODE=local \
PCC_DURATION="${PCC_DURATION}s" \
PCC_FREQUENCY="$FREQUENCY" \
PCC_COLLECTION="$RESULTS_DIR/host_collection.json" \
    "$PCC_BIN" > "$RESULTS_DIR/host_pcc.log" 2>&1 &
HOST_PCC_PID=$!

echo ""

# Start container pcc if available
if [ "$COLLECT_CONTAINERS" = true ]; then
    echo "  Starting CONTAINER pcc collector..."
    echo "    Duration: ${PCC_DURATION}s"
    echo "    Frequency: ${FREQUENCY}"
    echo "    Output: ${RESULTS_DIR}/container_collection.json"

    PCC_CONTAINER_DURATION="${PCC_DURATION}s" \
    PCC_CONTAINER_FREQUENCY="$FREQUENCY" \
    PCC_CONTAINER_COLLECTION="$RESULTS_DIR/container_collection.json" \
        "$PCC_CONTAINER_BIN" > "$RESULTS_DIR/container_pcc.log" 2>&1 &
    CONTAINER_PCC_PID=$!
fi

echo ""

#############################################
# PHASE 3: VERIFY COLLECTORS (CRITICAL!)
#############################################
echo -e "${YELLOW}━━━ PHASE 3: Verifying Collectors ━━━${NC}"
echo ""
echo -e "${RED}  *** THIS VERIFICATION IS MANDATORY ***${NC}"
echo -e "${RED}  *** TEST WILL ABORT IF COLLECTION FAILS ***${NC}"
echo ""

# Verify HOST pcc - REQUIRED
if ! verify_pcc_collecting "$HOST_PCC_PID" "$RESULTS_DIR/host_collection.json" "Host" "$RESULTS_DIR/host_pcc.log" 5; then
    abort_test "Host pcc collection verification failed!"
fi

# Verify container pcc - optional
if [ "$COLLECT_CONTAINERS" = true ] && [ -n "$CONTAINER_PCC_PID" ]; then
    if ! verify_pcc_collecting "$CONTAINER_PCC_PID" "$RESULTS_DIR/container_collection.json" "Container" "$RESULTS_DIR/container_pcc.log" 5; then
        echo -e "${YELLOW}  ⚠ Container collection failed, continuing with host only${NC}"
        COLLECT_CONTAINERS=false
    fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ALL COLLECTORS VERIFIED - PROCEEDING WITH LOAD TEST${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

#############################################
# PHASE 4: START LOAD TESTS
#############################################
echo -e "${YELLOW}━━━ PHASE 4: Starting Load Tests ━━━${NC}"
echo ""
echo "  Start time: $(date)"
echo "  Duration: ${DURATION_SECONDS} seconds (${DURATION_MINUTES} minutes)"
echo ""

# Start host sysbench
echo "  Starting host sysbench (${SYSBENCH_THREADS} threads)..."
sysbench cpu --threads=$SYSBENCH_THREADS --time=$DURATION_SECONDS run > "$RESULTS_DIR/host_sysbench.log" 2>&1 &
HOST_SYSBENCH_PID=$!

# Start container sysbench tests
if [ "$COLLECT_CONTAINERS" = true ]; then
    CONTAINERS=$(sudo docker ps --format '{{.Names}}' 2>/dev/null || echo "")
    for CONTAINER in $CONTAINERS; do
        echo "  Starting sysbench in container: $CONTAINER"
        sudo docker exec -d "$CONTAINER" bash -c \
            "command -v sysbench && sysbench cpu --threads=1 --time=$DURATION_SECONDS run > /tmp/sysbench.log 2>&1" 2>/dev/null || true
    done
fi

echo ""
echo "  Load tests running..."
echo ""

# Progress monitoring with collection verification
ELAPSED=0
INTERVAL=60
while [ $ELAPSED -lt $DURATION_SECONDS ]; do
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))

    # Check host pcc still running
    if ! ps -p $HOST_PCC_PID > /dev/null 2>&1; then
        echo -e "${RED}  ✗ WARNING: Host pcc stopped at ${ELAPSED}s!${NC}"
    fi

    # Report progress
    HOST_SAMPLES=$(wc -l < "$RESULTS_DIR/host_collection.json" 2>/dev/null || echo 0)
    REMAINING=$((DURATION_SECONDS - ELAPSED))

    if [ "$COLLECT_CONTAINERS" = true ] && [ -f "$RESULTS_DIR/container_collection.json" ]; then
        CONTAINER_SAMPLES=$(wc -l < "$RESULTS_DIR/container_collection.json" 2>/dev/null || echo 0)
        echo "  [${ELAPSED}s/${DURATION_SECONDS}s] Host: ${HOST_SAMPLES} samples, Containers: ${CONTAINER_SAMPLES} samples"
    else
        echo "  [${ELAPSED}s/${DURATION_SECONDS}s] Host: ${HOST_SAMPLES} samples"
    fi
done

# Wait for sysbench to complete
echo ""
echo "  Waiting for sysbench to complete..."
wait $HOST_SYSBENCH_PID 2>/dev/null || true

# Wait for pcc buffer
echo "  Waiting ${PCC_BUFFER_SECONDS}s for final pcc samples..."
sleep $PCC_BUFFER_SECONDS

#############################################
# PHASE 5: COLLECT RESULTS
#############################################
echo ""
echo -e "${YELLOW}━━━ PHASE 5: Collecting Results ━━━${NC}"
echo ""

# Stop pcc processes gracefully
kill $HOST_PCC_PID 2>/dev/null || true
[ -n "$CONTAINER_PCC_PID" ] && kill $CONTAINER_PCC_PID 2>/dev/null || true
sleep 2

# Collect container logs and create name mapping
if [ "$COLLECT_CONTAINERS" = true ]; then
    CONTAINERS=$(sudo docker ps --format '{{.Names}}' 2>/dev/null || echo "")

    # Copy sysbench logs from containers
    for CONTAINER in $CONTAINERS; do
        sudo docker cp "$CONTAINER:/tmp/sysbench.log" "$RESULTS_DIR/${CONTAINER}_sysbench.log" 2>/dev/null || true
    done

    # Create container name mapping JSON
    echo "{" > "$RESULTS_DIR/container_names.json"
    FIRST=true
    for CONTAINER in $CONTAINERS; do
        CONTAINER_ID=$(sudo docker inspect "$CONTAINER" --format '{{.Id}}' 2>/dev/null || echo "")
        if [ -n "$CONTAINER_ID" ]; then
            [ "$FIRST" = true ] && FIRST=false || echo "," >> "$RESULTS_DIR/container_names.json"
            echo "  \"$CONTAINER_ID\": \"$CONTAINER\"" >> "$RESULTS_DIR/container_names.json"
        fi
    done
    echo "" >> "$RESULTS_DIR/container_names.json"
    echo "}" >> "$RESULTS_DIR/container_names.json"
fi

# Collect system info
echo "  Collecting system information..."
mkdir -p "$RESULTS_DIR/system_info"

# CPU info
cat /proc/cpuinfo > "$RESULTS_DIR/system_info/cpuinfo.txt" 2>/dev/null || true

# Memory info
cat /proc/meminfo > "$RESULTS_DIR/system_info/meminfo.txt" 2>/dev/null || true

# Create system_info.json
if [ -f "$RESULTS_DIR/system_info/cpuinfo.txt" ]; then
    python3 - << 'PYEOF' "$RESULTS_DIR/system_info/cpuinfo.txt" "$RESULTS_DIR/system_info/system_info.json" 2>/dev/null || true
import sys
import json
import re

cpuinfo_file = sys.argv[1]
output_file = sys.argv[2]

with open(cpuinfo_file, 'r') as f:
    content = f.read()

info = {}
for line in content.split('\n'):
    if ':' in line:
        key, value = line.split(':', 1)
        key = key.strip().replace(' ', '_').lower()
        value = value.strip()
        if key not in info:
            info[key] = value

cpu_count = content.count('processor')

result = {
    'vendor_id': info.get('vendor_id', ''),
    'model_name': info.get('model_name', ''),
    'cpu_cores': int(info.get('cpu_cores', 1)) if info.get('cpu_cores', '').isdigit() else 1,
    'siblings': int(info.get('siblings', 1)) if info.get('siblings', '').isdigit() else 1,
    'total_cpus': cpu_count,
    'bogomips': float(info.get('bogomips', 0)) if info.get('bogomips', '').replace('.','').isdigit() else 0,
}

with open(output_file, 'w') as f:
    json.dump(result, f, indent=2)
PYEOF
fi

#############################################
# PHASE 6: SUMMARY
#############################################
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}              LOAD TEST COMPLETED SUCCESSFULLY${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo "  End time:  $(date)"
echo "  Results:   $RESULTS_DIR"
echo "  Timestamp: $TIMESTAMP"
echo ""

# Final statistics
echo "  Collection Statistics:"
if [ -f "$RESULTS_DIR/host_collection.json" ]; then
    HOST_FINAL=$(wc -l < "$RESULTS_DIR/host_collection.json")
    echo "    Host samples:      $HOST_FINAL"
fi
if [ -f "$RESULTS_DIR/container_collection.json" ]; then
    CONTAINER_FINAL=$(wc -l < "$RESULTS_DIR/container_collection.json")
    echo "    Container samples: $CONTAINER_FINAL"
fi

echo ""
echo "  Files created:"
ls -la "$RESULTS_DIR/" | grep -v "^total" | grep -v "^d"

echo ""
echo -e "${GREEN}============================================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Download results: scp -r user@host:$RESULTS_DIR ./"
echo "  2. Process host data: pcprocess -collection host_collection.json -outdir csv/"
echo "  3. Process container data: python convert_container_json_to_csv.py ..."
echo "  4. Import to portal"
echo ""
