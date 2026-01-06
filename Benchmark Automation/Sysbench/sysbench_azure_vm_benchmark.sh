#!/bin/bash

# Azure VM Benchmark Script
# Runs CPU, memory, and I/O stress tests for comparison between servers
# Total runtime: approximately 1 hour

set -e

# Configuration
BENCHMARK_DURATION=1200  # 20 minutes per test (3 tests = 60 minutes)
FILEIO_SIZE="10G"
OUTPUT_DIR="./benchmark_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname)
RESULT_FILE="${OUTPUT_DIR}/${HOSTNAME}_benchmark_${TIMESTAMP}.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}============================================${NC}"
}

print_status() {
    echo -e "${YELLOW}>>> $1${NC}"
}

# Check if sysbench is installed
check_dependencies() {
    print_header "Checking Dependencies"

    if ! command -v sysbench &> /dev/null; then
        print_status "sysbench not found. Installing..."
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y sysbench
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y sysbench
        elif command -v yum &> /dev/null; then
            sudo yum install -y sysbench
        else
            echo -e "${RED}Could not install sysbench. Please install manually.${NC}"
            exit 1
        fi
    fi

    echo "sysbench version: $(sysbench --version)"
}

# Collect system information
collect_system_info() {
    print_header "Collecting System Information"

    {
        echo "========================================"
        echo "BENCHMARK RESULTS"
        echo "========================================"
        echo ""
        echo "Hostname: $HOSTNAME"
        echo "Date: $(date)"
        echo "Kernel: $(uname -r)"
        echo ""
        echo "--- CPU Information ---"
        lscpu | grep -E "^(Architecture|CPU\(s\)|Model name|CPU MHz|CPU max MHz|Thread|Core|Socket)"
        echo ""
        echo "--- Memory Information ---"
        free -h
        echo ""
        echo "--- Disk Information ---"
        df -h /
        echo ""
        echo "--- Azure VM Size (if available) ---"
        if command -v curl &> /dev/null; then
            curl -s -H Metadata:true --noproxy "*" \
                "http://169.254.169.254/metadata/instance/compute/vmSize?api-version=2021-02-01&format=text" 2>/dev/null || echo "Not available"
        fi
        echo ""
    } | tee -a "$RESULT_FILE"
}

# CPU Benchmark
run_cpu_benchmark() {
    print_header "Running CPU Benchmark (${BENCHMARK_DURATION}s)"

    local threads=$(nproc)
    print_status "Using $threads threads"

    {
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
    } | tee -a "$RESULT_FILE"
}

# Memory Benchmark
run_memory_benchmark() {
    print_header "Running Memory Benchmark (${BENCHMARK_DURATION}s)"

    local threads=$(nproc)
    print_status "Using $threads threads"

    {
        echo ""
        echo "========================================"
        echo "MEMORY BENCHMARK"
        echo "========================================"
        echo "Threads: $threads"
        echo "Duration: ${BENCHMARK_DURATION}s"
        echo "Block size: 1K"
        echo "Total size: 100G"
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
    } | tee -a "$RESULT_FILE"
}

# I/O Benchmark
run_io_benchmark() {
    print_header "Running I/O Benchmark (${BENCHMARK_DURATION}s)"

    local threads=$(nproc)
    local io_dir="${OUTPUT_DIR}/fileio_test"

    print_status "Using $threads threads"
    print_status "Creating test files (${FILEIO_SIZE})..."

    mkdir -p "$io_dir"
    cd "$io_dir"

    # Prepare test files
    sysbench fileio --file-total-size=$FILEIO_SIZE prepare

    {
        echo ""
        echo "========================================"
        echo "I/O BENCHMARK"
        echo "========================================"
        echo "Threads: $threads"
        echo "Duration: ${BENCHMARK_DURATION}s"
        echo "File size: $FILEIO_SIZE"
        echo ""

        echo "--- Sequential Read ---"
        sysbench fileio \
            --threads=$threads \
            --time=$((BENCHMARK_DURATION / 4)) \
            --file-total-size=$FILEIO_SIZE \
            --file-test-mode=seqrd \
            run

        echo ""
        echo "--- Sequential Write ---"
        sysbench fileio \
            --threads=$threads \
            --time=$((BENCHMARK_DURATION / 4)) \
            --file-total-size=$FILEIO_SIZE \
            --file-test-mode=seqwr \
            run

        echo ""
        echo "--- Random Read ---"
        sysbench fileio \
            --threads=$threads \
            --time=$((BENCHMARK_DURATION / 4)) \
            --file-total-size=$FILEIO_SIZE \
            --file-test-mode=rndrd \
            run

        echo ""
        echo "--- Random Read/Write ---"
        sysbench fileio \
            --threads=$threads \
            --time=$((BENCHMARK_DURATION / 4)) \
            --file-total-size=$FILEIO_SIZE \
            --file-test-mode=rndrw \
            run
    } | tee -a "$RESULT_FILE"

    # Cleanup test files
    print_status "Cleaning up I/O test files..."
    sysbench fileio --file-total-size=$FILEIO_SIZE cleanup
    cd - > /dev/null
    rmdir "$io_dir" 2>/dev/null || true
}

# Generate summary
generate_summary() {
    print_header "Generating Summary"

    {
        echo ""
        echo "========================================"
        echo "SUMMARY"
        echo "========================================"
        echo ""
        echo "Benchmark completed at: $(date)"
        echo "Results saved to: $RESULT_FILE"
        echo ""
        echo "--- Key Metrics ---"
        echo ""
        echo "CPU: Look for 'events per second' - higher is better"
        echo "Memory: Look for 'transferred' (MiB/sec) - higher is better"
        echo "I/O: Look for 'read, MiB/s' and 'written, MiB/s' - higher is better"
        echo ""
    } | tee -a "$RESULT_FILE"
}

# Main execution
main() {
    echo ""
    print_header "Azure VM Benchmark Script"
    echo "Total estimated runtime: ~60 minutes"
    echo "Results will be saved to: $RESULT_FILE"
    echo ""

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Run benchmarks
    check_dependencies
    collect_system_info

    START_TIME=$(date +%s)

    run_cpu_benchmark
    run_memory_benchmark
    run_io_benchmark

    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))

    generate_summary

    echo ""
    print_header "Benchmark Complete!"
    echo "Total runtime: $((ELAPSED / 60)) minutes $((ELAPSED % 60)) seconds"
    echo "Results saved to: $RESULT_FILE"
    echo ""
    echo "To compare results from two VMs, copy the result files to the same"
    echo "location and use diff or a comparison tool:"
    echo "  diff vm1_benchmark.txt vm2_benchmark.txt"
    echo ""
}

# Run main function
main "$@"
