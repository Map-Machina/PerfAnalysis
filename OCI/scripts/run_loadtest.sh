#!/bin/bash
#
# Synchronized Load Test Script for OCI VMs
#
# This script ensures pcc collection is running BEFORE starting load tests.
# It will abort if collection fails to start properly.
#
# Usage: ./run_loadtest.sh [duration_minutes]
#
# Prerequisites:
#   - pcc-linux binary in home directory
#   - pcc-container-linux binary in home directory
#   - sysbench installed on host
#   - Docker containers with sysbench installed
#

set -e  # Exit on any error

# Configuration
DURATION_MINUTES=${1:-10}
DURATION_SECONDS=$((DURATION_MINUTES * 60))
PCC_BUFFER_SECONDS=30
FREQUENCY="5s"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR=~/results/$TIMESTAMP

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================================"
echo "PerfAnalysis Load Test Script"
echo "============================================================"
echo "Duration: ${DURATION_MINUTES} minutes (${DURATION_SECONDS} seconds)"
echo "Results directory: ${RESULTS_DIR}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

#############################################
# PHASE 1: PRE-FLIGHT CHECKS
#############################################
echo -e "${YELLOW}PHASE 1: Pre-flight checks${NC}"

# Check for pcc binaries
if [ ! -x ~/pcc-linux ]; then
    echo -e "${RED}ERROR: ~/pcc-linux not found or not executable${NC}"
    exit 1
fi
echo "  ✓ pcc-linux found"

if [ ! -x ~/pcc-container-linux ]; then
    echo -e "${RED}ERROR: ~/pcc-container-linux not found or not executable${NC}"
    exit 1
fi
echo "  ✓ pcc-container-linux found"

# Check for sysbench
if ! command -v sysbench &> /dev/null; then
    echo -e "${RED}ERROR: sysbench not installed${NC}"
    exit 1
fi
echo "  ✓ sysbench installed"

# Check for running containers
CONTAINER_COUNT=$(sudo docker ps -q | wc -l)
if [ "$CONTAINER_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}WARNING: No running containers found${NC}"
else
    echo "  ✓ Found ${CONTAINER_COUNT} running containers"
fi

echo ""

#############################################
# PHASE 2: START PCC COLLECTORS
#############################################
echo -e "${YELLOW}PHASE 2: Starting PCC collectors${NC}"

# Kill any existing pcc processes
pkill -f pcc-linux 2>/dev/null || true
pkill -f pcc-container-linux 2>/dev/null || true
sleep 2

# Calculate total collection duration (test duration + buffer)
PCC_DURATION=$((DURATION_SECONDS + PCC_BUFFER_SECONDS))

# Start HOST pcc with LOCAL MODE (CRITICAL!)
echo "  Starting host pcc (local mode)..."
PCC_MODE=local \
PCC_DURATION="${PCC_DURATION}s" \
PCC_FREQUENCY="$FREQUENCY" \
PCC_COLLECTION="$RESULTS_DIR/host_collection.json" \
    ~/pcc-linux > "$RESULTS_DIR/host_pcc.log" 2>&1 &
HOST_PCC_PID=$!

# Start container pcc
echo "  Starting container pcc..."
PCC_CONTAINER_DURATION="${PCC_DURATION}s" \
PCC_CONTAINER_FREQUENCY="$FREQUENCY" \
PCC_CONTAINER_COLLECTION="$RESULTS_DIR/container_collection.json" \
    ~/pcc-container-linux > "$RESULTS_DIR/container_pcc.log" 2>&1 &
CONTAINER_PCC_PID=$!

# Wait for collectors to initialize
echo "  Waiting for collectors to initialize (5 seconds)..."
sleep 5

#############################################
# PHASE 3: VERIFY COLLECTORS ARE RUNNING
#############################################
echo -e "${YELLOW}PHASE 3: Verifying collectors${NC}"

# Check host pcc is running
if ! ps -p $HOST_PCC_PID > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Host pcc failed to start!${NC}"
    echo "Log contents:"
    cat "$RESULTS_DIR/host_pcc.log"
    exit 1
fi
echo "  ✓ Host pcc running (PID: $HOST_PCC_PID)"

# Check host collection file exists and has data
if [ ! -f "$RESULTS_DIR/host_collection.json" ]; then
    echo -e "${RED}ERROR: Host collection file not created!${NC}"
    echo "This usually means PCC_MODE=local was not set correctly."
    echo "Log contents:"
    cat "$RESULTS_DIR/host_pcc.log"
    kill $HOST_PCC_PID 2>/dev/null || true
    kill $CONTAINER_PCC_PID 2>/dev/null || true
    exit 1
fi

HOST_LINES=$(wc -l < "$RESULTS_DIR/host_collection.json")
if [ "$HOST_LINES" -eq 0 ]; then
    echo -e "${RED}ERROR: Host collection file is empty!${NC}"
    cat "$RESULTS_DIR/host_pcc.log"
    kill $HOST_PCC_PID 2>/dev/null || true
    kill $CONTAINER_PCC_PID 2>/dev/null || true
    exit 1
fi
echo "  ✓ Host collection file created ($HOST_LINES lines)"

# Check container pcc is running
if ! ps -p $CONTAINER_PCC_PID > /dev/null 2>&1; then
    echo -e "${YELLOW}WARNING: Container pcc not running (may be OK if no containers)${NC}"
else
    echo "  ✓ Container pcc running (PID: $CONTAINER_PCC_PID)"

    if [ -f "$RESULTS_DIR/container_collection.json" ]; then
        CONTAINER_LINES=$(wc -l < "$RESULTS_DIR/container_collection.json")
        echo "  ✓ Container collection file created ($CONTAINER_LINES lines)"
    fi
fi

echo ""
echo -e "${GREEN}All collectors verified and running!${NC}"
echo ""

#############################################
# PHASE 4: START LOAD TESTS
#############################################
echo -e "${YELLOW}PHASE 4: Starting load tests${NC}"
echo "  Test duration: ${DURATION_SECONDS} seconds"

# Start host sysbench
echo "  Starting host sysbench (2 threads)..."
sysbench cpu --threads=2 --time=$DURATION_SECONDS run > "$RESULTS_DIR/host_sysbench.log" 2>&1 &
HOST_SYSBENCH_PID=$!

# Start container sysbench tests
CONTAINERS=$(sudo docker ps --format '{{.Names}}')
for CONTAINER in $CONTAINERS; do
    echo "  Starting sysbench in container: $CONTAINER"
    sudo docker exec -d "$CONTAINER" bash -c \
        "sysbench cpu --threads=1 --time=$DURATION_SECONDS run > /tmp/sysbench.log 2>&1" 2>/dev/null || true
done

echo ""
echo "Load tests started at $(date)"
echo "Waiting ${DURATION_SECONDS} seconds for completion..."
echo ""

# Progress indicator
ELAPSED=0
while [ $ELAPSED -lt $DURATION_SECONDS ]; do
    sleep 60
    ELAPSED=$((ELAPSED + 60))
    REMAINING=$((DURATION_SECONDS - ELAPSED))

    # Verify collectors still running
    if ! ps -p $HOST_PCC_PID > /dev/null 2>&1; then
        echo -e "${RED}WARNING: Host pcc stopped unexpectedly!${NC}"
    fi

    HOST_LINES=$(wc -l < "$RESULTS_DIR/host_collection.json" 2>/dev/null || echo 0)
    echo "  [${ELAPSED}s elapsed] Host collection: ${HOST_LINES} samples"
done

# Wait for host sysbench to complete
wait $HOST_SYSBENCH_PID 2>/dev/null || true
echo ""
echo "Host sysbench completed"

# Wait for pcc buffer period
echo "Waiting ${PCC_BUFFER_SECONDS}s for pcc to finish..."
sleep $PCC_BUFFER_SECONDS

#############################################
# PHASE 5: COLLECT RESULTS
#############################################
echo ""
echo -e "${YELLOW}PHASE 5: Collecting results${NC}"

# Stop pcc processes
kill $HOST_PCC_PID 2>/dev/null || true
kill $CONTAINER_PCC_PID 2>/dev/null || true

# Copy container sysbench logs
for CONTAINER in $CONTAINERS; do
    sudo docker cp "$CONTAINER:/tmp/sysbench.log" "$RESULTS_DIR/${CONTAINER}_sysbench.log" 2>/dev/null || true
done

# Create container name mapping
echo "{" > "$RESULTS_DIR/container_names.json"
FIRST=true
for CONTAINER in $CONTAINERS; do
    CONTAINER_ID=$(sudo docker inspect "$CONTAINER" --format '{{.Id}}' 2>/dev/null)
    if [ -n "$CONTAINER_ID" ]; then
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            echo "," >> "$RESULTS_DIR/container_names.json"
        fi
        echo "  \"$CONTAINER_ID\": \"$CONTAINER\"" >> "$RESULTS_DIR/container_names.json"
    fi
done
echo "" >> "$RESULTS_DIR/container_names.json"
echo "}" >> "$RESULTS_DIR/container_names.json"

# Copy system info if exists
if [ -d ~/results/system_info ]; then
    cp -r ~/results/system_info "$RESULTS_DIR/"
fi

#############################################
# PHASE 6: SUMMARY
#############################################
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}LOAD TEST COMPLETE${NC}"
echo -e "${GREEN}============================================================${NC}"
echo "Results saved to: $RESULTS_DIR"
echo ""
echo "Files created:"
ls -la "$RESULTS_DIR/"

echo ""
echo "Collection statistics:"
if [ -f "$RESULTS_DIR/host_collection.json" ]; then
    HOST_SAMPLES=$(wc -l < "$RESULTS_DIR/host_collection.json")
    echo "  Host samples: $HOST_SAMPLES"
fi
if [ -f "$RESULTS_DIR/container_collection.json" ]; then
    CONTAINER_SAMPLES=$(wc -l < "$RESULTS_DIR/container_collection.json")
    echo "  Container samples: $CONTAINER_SAMPLES"
fi

echo ""
echo "Timestamp for download: $TIMESTAMP"
echo -e "${GREEN}============================================================${NC}"
