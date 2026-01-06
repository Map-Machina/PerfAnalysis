#!/bin/bash

# Sysbench + PCC Benchmark Orchestration Script
# Runs pcc collection and sysbench benchmark simultaneously on both Azure VMs
# Total runtime: ~70 minutes (pcc) with ~60 minutes (sysbench)

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

# Function to run benchmark on a single VM
run_vm_benchmark() {
    local vm_name=$1
    local vm_ip=$2
    local vm_user=$3
    local result_dir="${RESULTS_DIR}/${vm_name}"

    print_header "Starting benchmark on ${vm_name} (${vm_ip})"

    # Create remote working directory
    ssh ${vm_user}@${vm_ip} "mkdir -p ~/benchmark_results"

    # Start pcc in background (70 minutes, JSON output)
    # pcc uses environment variables: PCC_DURATION, PCC_FREQUENCY, PCC_COLLECTION, PCC_MODE, PCC_APIKEY
    print_status "Starting pcc collection on ${vm_name} (${PCC_DURATION} duration)..."
    ssh ${vm_user}@${vm_ip} "nohup env PCC_APIKEY=benchmark PCC_MODE=local PCC_DURATION=${PCC_DURATION} PCC_FREQUENCY=${PCC_FREQUENCY} PCC_COLLECTION=~/benchmark_results/pcc_collection_${TIMESTAMP}.json pcc > ~/benchmark_results/pcc_${TIMESTAMP}.log 2>&1 &"

    # Give pcc a moment to start
    sleep 5

    # Verify pcc is running
    if ssh ${vm_user}@${vm_ip} "pgrep -x pcc > /dev/null"; then
        print_info "pcc is running on ${vm_name}"
    else
        echo -e "${RED}ERROR: pcc failed to start on ${vm_name}${NC}"
        return 1
    fi

    # Start sysbench benchmark (runs for ~60 minutes)
    print_status "Starting sysbench benchmark on ${vm_name}..."
    ssh ${vm_user}@${vm_ip} "cd ~/benchmark_results && ~/sysbench_azure_vm_benchmark.sh" &

    echo $!  # Return the background job PID
}

# Function to wait for VM benchmark completion and collect results
collect_results() {
    local vm_name=$1
    local vm_ip=$2
    local vm_user=$3
    local result_dir="${RESULTS_DIR}/${vm_name}"

    print_header "Collecting results from ${vm_name}"

    # Wait for pcc to finish (check if process is still running)
    print_status "Waiting for pcc to complete on ${vm_name}..."
    while ssh ${vm_user}@${vm_ip} "pgrep -x pcc > /dev/null 2>&1"; do
        sleep 30
        print_info "pcc still running on ${vm_name}..."
    done

    print_info "pcc completed on ${vm_name}"

    # Copy results back
    print_status "Copying results from ${vm_name}..."
    scp ${vm_user}@${vm_ip}:~/benchmark_results/*.json "${result_dir}/" 2>/dev/null || true
    scp ${vm_user}@${vm_ip}:~/benchmark_results/*.txt "${result_dir}/" 2>/dev/null || true
    scp ${vm_user}@${vm_ip}:~/benchmark_results/*.log "${result_dir}/" 2>/dev/null || true

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

    # Verify connectivity
    print_status "Verifying SSH connectivity..."
    ssh -o ConnectTimeout=10 ${VM1_USER}@${VM1_IP} "echo 'Connected to ${VM1_NAME}'" || { echo -e "${RED}Cannot connect to ${VM1_NAME}${NC}"; exit 1; }
    ssh -o ConnectTimeout=10 ${VM2_USER}@${VM2_IP} "echo 'Connected to ${VM2_NAME}'" || { echo -e "${RED}Cannot connect to ${VM2_NAME}${NC}"; exit 1; }

    # Create result directories with timestamp
    mkdir -p "${RESULTS_DIR}/${VM1_NAME}"
    mkdir -p "${RESULTS_DIR}/${VM2_NAME}"

    # Start benchmarks on both VMs simultaneously
    print_header "Starting benchmarks on both VMs simultaneously"

    START_TIME=$(date +%s)

    # Run both VMs in parallel
    run_vm_benchmark "${VM1_NAME}" "${VM1_IP}" "${VM1_USER}" &
    PID1=$!

    run_vm_benchmark "${VM2_NAME}" "${VM2_IP}" "${VM2_USER}" &
    PID2=$!

    # Wait for sysbench to complete on both (background ssh processes)
    print_status "Waiting for sysbench benchmarks to complete (~60 minutes)..."
    wait $PID1 2>/dev/null || true
    wait $PID2 2>/dev/null || true

    print_info "Sysbench benchmarks completed. Waiting for pcc collection to finish..."

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
    ls -la "${RESULTS_DIR}/${VM1_NAME}/" 2>/dev/null || echo "  (no files yet)"
    ls -la "${RESULTS_DIR}/${VM2_NAME}/" 2>/dev/null || echo "  (no files yet)"
}

# Run main function
main "$@"
