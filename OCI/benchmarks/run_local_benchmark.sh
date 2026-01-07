#!/bin/bash

# Local OCI VM Benchmark Script
# Runs pcc collection and sysbench benchmark on the local OCI VM
# Total runtime: ~12 minutes (10 min benchmark + 2 min buffer)
#
# Usage: Run this script on the OCI VM as the pcc user
#   sudo su - pcc
#   ./run_local_benchmark.sh

set -e

# Configuration
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR=~/benchmark_results/${TIMESTAMP}
PCC_DURATION="12m"    # 12 minutes (covers benchmark + buffer)
PCC_FREQUENCY="5s"    # 5 second collection interval

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

# Check dependencies
check_dependencies() {
    print_header "Checking Dependencies"

    # Check for pcc
    if ! command -v pcc &> /dev/null; then
        if [ -f ~/perfcollector2/bin/pcc ]; then
            export PATH=$PATH:~/perfcollector2/bin
            print_info "Added pcc to PATH"
        else
            print_error "pcc not found. Please install perfcollector2."
            exit 1
        fi
    fi
    print_info "pcc version: $(pcc --version 2>/dev/null || echo 'available')"

    # Check for sysbench
    if ! command -v sysbench &> /dev/null; then
        print_status "sysbench not found. Installing..."
        if command -v dnf &> /dev/null; then
            sudo dnf install -y sysbench
        elif command -v yum &> /dev/null; then
            sudo yum install -y sysbench
        else
            print_error "Could not install sysbench. Please install manually."
            exit 1
        fi
    fi
    print_info "sysbench version: $(sysbench --version)"
}

# Start pcc collection
start_pcc() {
    print_header "Starting PCC Collection"

    mkdir -p ${RESULTS_DIR}

    export PCC_MODE=local
    export PCC_DURATION=${PCC_DURATION}
    export PCC_FREQUENCY=${PCC_FREQUENCY}
    export PCC_COLLECTION=${RESULTS_DIR}/pcc_collection_${TIMESTAMP}.json

    print_info "PCC Duration: ${PCC_DURATION}"
    print_info "PCC Frequency: ${PCC_FREQUENCY}"
    print_info "Collection file: ${PCC_COLLECTION}"

    # Start pcc in background
    nohup pcc > ${RESULTS_DIR}/pcc_${TIMESTAMP}.log 2>&1 &
    PCC_PID=$!
    echo $PCC_PID > ${RESULTS_DIR}/pcc.pid

    sleep 3

    if ps -p $PCC_PID > /dev/null 2>&1; then
        print_info "pcc started successfully (PID: $PCC_PID)"
        return 0
    else
        print_error "pcc failed to start"
        cat ${RESULTS_DIR}/pcc_${TIMESTAMP}.log
        return 1
    fi
}

# Run sysbench benchmark
run_sysbench() {
    print_header "Running Sysbench Benchmark"

    local BENCHMARK_DURATION=200  # ~3.3 minutes per test
    local threads=$(nproc)

    print_info "Using $threads threads"
    print_info "Benchmark duration: ${BENCHMARK_DURATION}s per test"

    RESULT_FILE=${RESULTS_DIR}/sysbench_${TIMESTAMP}.log

    {
        echo "========================================"
        echo "OCI VM BENCHMARK RESULTS"
        echo "========================================"
        echo ""
        echo "Hostname: $(hostname)"
        echo "Date: $(date)"
        echo "Kernel: $(uname -r)"
        echo ""
        echo "--- CPU Information ---"
        lscpu | grep -E "^(Architecture|CPU\(s\)|Model name|CPU MHz|Thread|Core|Socket)" || true
        echo ""
        echo "--- Memory Information ---"
        free -h
        echo ""
        echo "--- Disk Information ---"
        df -h /
        echo ""

        echo "========================================"
        echo "CPU BENCHMARK"
        echo "========================================"
        echo "Threads: $threads"
        echo "Duration: ${BENCHMARK_DURATION}s"
        echo ""
        sysbench cpu \
            --threads=$threads \
            --time=$BENCHMARK_DURATION \
            --cpu-max-prime=20000 \
            run

        echo ""
        echo "========================================"
        echo "MEMORY BENCHMARK"
        echo "========================================"
        echo "Threads: $threads"
        echo ""

        echo "--- Sequential Write ---"
        sysbench memory \
            --threads=$threads \
            --time=$((BENCHMARK_DURATION / 4)) \
            --memory-block-size=1K \
            --memory-total-size=100G \
            --memory-oper=write \
            --memory-access-mode=seq \
            run

        echo ""
        echo "--- Sequential Read ---"
        sysbench memory \
            --threads=$threads \
            --time=$((BENCHMARK_DURATION / 4)) \
            --memory-block-size=1K \
            --memory-total-size=100G \
            --memory-oper=read \
            --memory-access-mode=seq \
            run

        echo ""
        echo "--- Random Write ---"
        sysbench memory \
            --threads=$threads \
            --time=$((BENCHMARK_DURATION / 4)) \
            --memory-block-size=1K \
            --memory-total-size=100G \
            --memory-oper=write \
            --memory-access-mode=rnd \
            run

        echo ""
        echo "--- Random Read ---"
        sysbench memory \
            --threads=$threads \
            --time=$((BENCHMARK_DURATION / 4)) \
            --memory-block-size=1K \
            --memory-total-size=100G \
            --memory-oper=read \
            --memory-access-mode=rnd \
            run

        echo ""
        echo "========================================"
        echo "BENCHMARK COMPLETE"
        echo "========================================"
        echo "Completed at: $(date)"

    } 2>&1 | tee "$RESULT_FILE"

    print_info "Sysbench results saved to: $RESULT_FILE"
}

# Wait for pcc to complete and process results
wait_and_process() {
    print_header "Waiting for PCC to Complete"

    PCC_PID=$(cat ${RESULTS_DIR}/pcc.pid 2>/dev/null || echo "")

    if [ -n "$PCC_PID" ] && ps -p $PCC_PID > /dev/null 2>&1; then
        print_info "Waiting for pcc (PID: $PCC_PID) to complete..."

        while ps -p $PCC_PID > /dev/null 2>&1; do
            sleep 10
            print_info "pcc still running..."
        done

        print_info "pcc completed"
    fi

    # Process collection to CSV
    print_header "Processing Collection to CSV"

    PCC_COLLECTION=${RESULTS_DIR}/pcc_collection_${TIMESTAMP}.json

    if [ -f "$PCC_COLLECTION" ]; then
        if command -v pcprocess &> /dev/null || [ -f ~/perfcollector2/bin/pcprocess ]; then
            export PATH=$PATH:~/perfcollector2/bin
            pcprocess -collection "$PCC_COLLECTION" -outdir "${RESULTS_DIR}/"
            print_info "CSV files generated in ${RESULTS_DIR}/"
        else
            print_error "pcprocess not found. JSON collection saved but not converted to CSV."
        fi
    else
        print_error "Collection file not found: $PCC_COLLECTION"
    fi
}

# Generate summary
generate_summary() {
    print_header "Benchmark Summary"

    echo ""
    echo "Results directory: ${RESULTS_DIR}"
    echo ""
    echo "Files generated:"
    ls -la ${RESULTS_DIR}/
    echo ""
    echo "To copy results to your local machine, use scp or OCI Cloud Shell download."
    echo ""
}

# Main execution
main() {
    print_header "OCI VM Local Benchmark Script"
    echo "Timestamp: ${TIMESTAMP}"
    echo "PCC Duration: ${PCC_DURATION}"
    echo "PCC Frequency: ${PCC_FREQUENCY}"
    echo ""

    START_TIME=$(date +%s)

    check_dependencies
    start_pcc
    run_sysbench
    wait_and_process
    generate_summary

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))

    print_header "Benchmark Complete!"
    echo "Total runtime: $((ELAPSED / 60)) minutes $((ELAPSED % 60)) seconds"
    echo "Results saved to: ${RESULTS_DIR}"
    echo ""
}

# Run main function
main "$@"
