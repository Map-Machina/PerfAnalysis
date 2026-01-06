#!/bin/bash

# Sysbench + PCC Benchmark Orchestration Script
# Runs pcc collection and sysbench benchmark simultaneously on both Azure VMs
# Total runtime: ~70 minutes (pcc) with ~60 minutes (sysbench)
#
# SYNCHRONIZATION: This script ensures both VMs start sysbench at the same time
# by first starting pcc on both, then starting sysbench simultaneously.

set -e

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="$(dirname "$0")/results"
PCC_DURATION="70m"    # 1 hour 10 minutes
PCC_FREQUENCY="5s"    # 5 second collection interval

# VM Configuration
VM1_NAME="pcc-test-01"
VM1_IP="4.155.247.78"
VM1_USER="azureuser"

VM2_NAME="pcc-e2e-test"
VM2_IP="4.155.213.76"
VM2_USER="testuser"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}============================================${NC}"
}

print_status() {
    echo -e "${YELLOW}>>> $1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Function to start pcc on a VM
start_pcc() {
    local vm_name=$1
    local vm_ip=$2
    local vm_user=$3

    print_status "Starting pcc on ${vm_name}..."

    # Create remote working directory
    ssh ${vm_user}@${vm_ip} "mkdir -p ~/benchmark_results"

    # Start pcc in background
    ssh ${vm_user}@${vm_ip} "nohup env PCC_APIKEY=benchmark PCC_MODE=local PCC_DURATION=${PCC_DURATION} PCC_FREQUENCY=${PCC_FREQUENCY} PCC_COLLECTION=~/benchmark_results/pcc_collection_${TIMESTAMP}.json pcc > ~/benchmark_results/pcc_${TIMESTAMP}.log 2>&1 &"

    # Verify pcc is running
    sleep 3
    if ssh ${vm_user}@${vm_ip} "pgrep -x pcc > /dev/null"; then
        print_info "pcc is running on ${vm_name}"
        return 0
    else
        print_error "pcc failed to start on ${vm_name}"
        return 1
    fi
}

# Function to start sysbench on a VM (runs in foreground of SSH, but we background the SSH)
start_sysbench() {
    local vm_name=$1
    local vm_ip=$2
    local vm_user=$3

    print_info "Starting sysbench on ${vm_name}..."
    ssh ${vm_user}@${vm_ip} "cd ~/benchmark_results && nohup ~/sysbench_azure_vm_benchmark.sh > sysbench_${TIMESTAMP}.log 2>&1 &"
}

# Function to verify sysbench is running
verify_sysbench() {
    local vm_name=$1
    local vm_ip=$2
    local vm_user=$3
    local max_retries=5
    local retry=0

    while [ $retry -lt $max_retries ]; do
        sleep 2
        if ssh ${vm_user}@${vm_ip} "pgrep -f sysbench > /dev/null 2>&1"; then
            print_info "sysbench confirmed running on ${vm_name}"
            return 0
        fi
        retry=$((retry + 1))
        print_info "Waiting for sysbench to start on ${vm_name} (attempt ${retry}/${max_retries})..."
    done

    print_error "sysbench failed to start on ${vm_name}"
    return 1
}

# Function to wait for VM benchmark completion and collect results
collect_results() {
    local vm_name=$1
    local vm_ip=$2
    local vm_user=$3
    local result_dir="${RESULTS_DIR}/${vm_name}"

    print_header "Collecting results from ${vm_name}"

    # Wait for pcc to finish
    print_status "Waiting for pcc to complete on ${vm_name}..."
    while ssh ${vm_user}@${vm_ip} "pgrep -x pcc > /dev/null 2>&1"; do
        sleep 30
        print_info "pcc still running on ${vm_name}..."
    done

    print_info "pcc completed on ${vm_name}"

    # Copy results back - handle files individually to avoid glob issues
    print_status "Copying results from ${vm_name}..."

    # Get list of files and copy each
    for ext in json log txt; do
        ssh ${vm_user}@${vm_ip} "ls ~/benchmark_results/*.${ext} 2>/dev/null" | while read -r filepath; do
            filename=$(basename "$filepath")
            scp "${vm_user}@${vm_ip}:${filepath}" "${result_dir}/${filename}" 2>/dev/null || true
        done
    done

    # Also check nested benchmark_results directory
    ssh ${vm_user}@${vm_ip} "ls ~/benchmark_results/benchmark_results/*.txt 2>/dev/null" | while read -r filepath; do
        filename=$(basename "$filepath")
        scp "${vm_user}@${vm_ip}:${filepath}" "${result_dir}/${filename}" 2>/dev/null || true
    done

    print_info "Results saved to ${result_dir}"
}

# Main execution
main() {
    print_header "Sysbench + PCC Benchmark Test"
    echo "Timestamp: ${TIMESTAMP}"
    echo "PCC Duration: ${PCC_DURATION}"
    echo "PCC Frequency: ${PCC_FREQUENCY}"
    echo ""
    echo "Target VMs:"
    echo "  - ${VM1_NAME} (${VM1_IP})"
    echo "  - ${VM2_NAME} (${VM2_IP})"
    echo ""

    # Verify connectivity to both VMs first
    print_status "Verifying SSH connectivity..."
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes ${VM1_USER}@${VM1_IP} "echo 'Connected'" > /dev/null 2>&1; then
        print_error "Cannot connect to ${VM1_NAME} (${VM1_IP})"
        exit 1
    fi
    print_info "Connected to ${VM1_NAME}"

    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes ${VM2_USER}@${VM2_IP} "echo 'Connected'" > /dev/null 2>&1; then
        print_error "Cannot connect to ${VM2_NAME} (${VM2_IP})"
        exit 1
    fi
    print_info "Connected to ${VM2_NAME}"

    # Create result directories
    mkdir -p "${RESULTS_DIR}/${VM1_NAME}"
    mkdir -p "${RESULTS_DIR}/${VM2_NAME}"

    START_TIME=$(date +%s)

    # PHASE 1: Start pcc on both VMs
    print_header "Phase 1: Starting PCC collection on both VMs"

    start_pcc "${VM1_NAME}" "${VM1_IP}" "${VM1_USER}" || exit 1
    start_pcc "${VM2_NAME}" "${VM2_IP}" "${VM2_USER}" || exit 1

    print_info "PCC running on both VMs"

    # PHASE 2: Start sysbench on both VMs SIMULTANEOUSLY
    print_header "Phase 2: Starting sysbench on both VMs simultaneously"

    # Calculate a synchronized start time (10 seconds from now)
    SYNC_TIME=$(($(date +%s) + 10))
    print_info "Synchronized start time: $(date -r ${SYNC_TIME} '+%Y-%m-%d %H:%M:%S')"

    # Deploy synchronized start command to both VMs
    # The VMs will wait until SYNC_TIME before starting sysbench
    ssh ${VM1_USER}@${VM1_IP} "while [ \$(date +%s) -lt ${SYNC_TIME} ]; do sleep 0.5; done; cd ~/benchmark_results && nohup ~/sysbench_azure_vm_benchmark.sh > sysbench_${TIMESTAMP}.log 2>&1 &" &
    PID1=$!

    ssh ${VM2_USER}@${VM2_IP} "while [ \$(date +%s) -lt ${SYNC_TIME} ]; do sleep 0.5; done; cd ~/benchmark_results && nohup ~/sysbench_azure_vm_benchmark.sh > sysbench_${TIMESTAMP}.log 2>&1 &" &
    PID2=$!

    # Wait for SSH commands to complete (they start nohup and exit quickly)
    wait $PID1 2>/dev/null || true
    wait $PID2 2>/dev/null || true

    # Give sysbench a moment to start, then verify
    sleep 5

    # Verify sysbench is running on both
    print_status "Verifying sysbench is running on both VMs..."

    SYSBENCH_OK=true
    if ! verify_sysbench "${VM1_NAME}" "${VM1_IP}" "${VM1_USER}"; then
        SYSBENCH_OK=false
    fi
    if ! verify_sysbench "${VM2_NAME}" "${VM2_IP}" "${VM2_USER}"; then
        SYSBENCH_OK=false
    fi

    if [ "$SYSBENCH_OK" = false ]; then
        print_error "Sysbench failed to start on one or more VMs"
        print_status "Check logs on VMs: ~/benchmark_results/sysbench_${TIMESTAMP}.log"
        exit 1
    fi

    print_header "Benchmarks Running"
    echo "Both pcc and sysbench are now running on both VMs."
    echo ""
    echo "Expected completion times:"
    echo "  Sysbench: ~60 minutes"
    echo "  PCC:      ~70 minutes"
    echo ""
    print_status "Waiting for benchmarks to complete..."

    # Wait for sysbench to finish (check every 60 seconds)
    while true; do
        VM1_SYSBENCH=$(ssh ${VM1_USER}@${VM1_IP} "pgrep -f sysbench_azure > /dev/null 2>&1 && echo 'running' || echo 'done'")
        VM2_SYSBENCH=$(ssh ${VM2_USER}@${VM2_IP} "pgrep -f sysbench_azure > /dev/null 2>&1 && echo 'running' || echo 'done'")

        if [ "$VM1_SYSBENCH" = "done" ] && [ "$VM2_SYSBENCH" = "done" ]; then
            print_info "Sysbench completed on both VMs"
            break
        fi

        ELAPSED=$(($(date +%s) - START_TIME))
        print_info "Sysbench running... (${VM1_NAME}: ${VM1_SYSBENCH}, ${VM2_NAME}: ${VM2_SYSBENCH}) - Elapsed: $((ELAPSED / 60))m"
        sleep 60
    done

    print_info "Waiting for pcc to finish collecting data..."

    # Collect results from both VMs
    collect_results "${VM1_NAME}" "${VM1_IP}" "${VM1_USER}"
    collect_results "${VM2_NAME}" "${VM2_IP}" "${VM2_USER}"

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))

    print_header "Benchmark Test Complete!"
    echo "Total runtime: $((ELAPSED / 60)) minutes $((ELAPSED % 60)) seconds"
    echo ""
    echo "Results saved to:"
    echo "  - ${RESULTS_DIR}/${VM1_NAME}/"
    echo "  - ${RESULTS_DIR}/${VM2_NAME}/"
    echo ""
    echo "Files:"
    ls -la "${RESULTS_DIR}/${VM1_NAME}/" 2>/dev/null || echo "  (no files)"
    echo ""
    ls -la "${RESULTS_DIR}/${VM2_NAME}/" 2>/dev/null || echo "  (no files)"
}

# Run main function
main "$@"
