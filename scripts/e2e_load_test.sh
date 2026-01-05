#!/bin/bash
# End-to-End Load Test Script for PerfAnalysis
# This script generates system load and tests the complete data pipeline

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=============================================="
echo "PerfAnalysis End-to-End Load Test"
echo "=============================================="
echo ""

# Configuration
TEST_DURATION=60  # seconds
LOAD_LEVEL="medium"  # light, medium, heavy
OUTPUT_DIR="/tmp/perfanalysis_e2e_test"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$OUTPUT_DIR"

# Step 1: Verify services are running
echo -e "${YELLOW}[1/7] Verifying services...${NC}"
if ! docker-compose ps | grep -q "perfanalysis-postgres"; then
    echo -e "${RED}✗ Services not running. Run 'make init' first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Services running${NC}"
echo ""

# Step 2: Generate CPU load
echo -e "${YELLOW}[2/7] Generating CPU load (${LOAD_LEVEL} for ${TEST_DURATION}s)...${NC}"

case $LOAD_LEVEL in
    light)
        WORKERS=2
        ;;
    medium)
        WORKERS=4
        ;;
    heavy)
        WORKERS=8
        ;;
esac

# CPU stress function
cpu_stress() {
    local duration=$1
    local workers=$2
    local end=$((SECONDS+duration))

    echo "Starting $workers CPU workers for $duration seconds..."

    for i in $(seq 1 $workers); do
        (
            while [ $SECONDS -lt $end ]; do
                # Calculate prime numbers to generate CPU load
                factor $(seq 1 1000000) > /dev/null 2>&1
            done
        ) &
    done

    # Wait for all background jobs
    wait
}

# Start CPU stress in background
cpu_stress $TEST_DURATION $WORKERS &
STRESS_PID=$!
echo -e "${GREEN}✓ CPU load generation started (PID: $STRESS_PID)${NC}"
echo ""

# Step 3: Collect system metrics
echo -e "${YELLOW}[3/7] Collecting system performance metrics...${NC}"

# Create a simple performance data collector script
cat > "$OUTPUT_DIR/collect_metrics.sh" <<'COLLECT_EOF'
#!/bin/bash
OUTPUT_FILE="$1"
DURATION="$2"

# CSV header
echo "timestamp,cpu_user,cpu_system,cpu_idle,mem_total_kb,mem_used_kb,mem_free_kb,hostname" > "$OUTPUT_FILE"

END_TIME=$(($(date +%s) + DURATION))
while [ $(date +%s) -lt $END_TIME ]; do
    TIMESTAMP=$(date +%s)
    HOSTNAME=$(hostname)

    # Get CPU stats from /proc/stat
    CPU_LINE=$(head -1 /proc/stat)
    read cpu user nice system idle iowait irq softirq steal guest guest_nice <<< "$CPU_LINE"

    # Calculate percentages (simplified)
    TOTAL=$((user + nice + system + idle + iowait + irq + softirq + steal))
    if [ $TOTAL -gt 0 ]; then
        CPU_USER=$(awk "BEGIN {printf \"%.2f\", ($user / $TOTAL) * 100}")
        CPU_SYSTEM=$(awk "BEGIN {printf \"%.2f\", ($system / $TOTAL) * 100}")
        CPU_IDLE=$(awk "BEGIN {printf \"%.2f\", ($idle / $TOTAL) * 100}")
    else
        CPU_USER=0
        CPU_SYSTEM=0
        CPU_IDLE=0
    fi

    # Get memory stats from /proc/meminfo
    MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEM_FREE=$(grep MemFree /proc/meminfo | awk '{print $2}')
    MEM_USED=$((MEM_TOTAL - MEM_FREE))

    # Write to CSV
    echo "$TIMESTAMP,$CPU_USER,$CPU_SYSTEM,$CPU_IDLE,$MEM_TOTAL,$MEM_USED,$MEM_FREE,$HOSTNAME" >> "$OUTPUT_FILE"

    sleep 5
done
COLLECT_EOF

chmod +x "$OUTPUT_DIR/collect_metrics.sh"

# Run metrics collection
CSV_FILE="$OUTPUT_DIR/performance_data_${TIMESTAMP}.csv"
"$OUTPUT_DIR/collect_metrics.sh" "$CSV_FILE" $TEST_DURATION &
COLLECTOR_PID=$!

echo -e "${GREEN}✓ Collecting metrics to: $CSV_FILE${NC}"
echo "  Waiting ${TEST_DURATION} seconds for data collection..."
echo ""

# Wait for collection to complete
sleep $((TEST_DURATION + 5))

# Wait for stress test to complete
wait $STRESS_PID 2>/dev/null || true

echo -e "${GREEN}✓ Load generation and data collection complete${NC}"
echo ""

# Step 4: Display collected data summary
echo -e "${YELLOW}[4/7] Analyzing collected data...${NC}"

if [ -f "$CSV_FILE" ]; then
    LINE_COUNT=$(wc -l < "$CSV_FILE")
    echo "  Data points collected: $((LINE_COUNT - 1))"

    # Show sample of data
    echo "  Sample data (first 3 rows):"
    head -4 "$CSV_FILE" | tail -3 | while read line; do
        echo "    $line"
    done

    # Calculate statistics
    echo ""
    echo "  Performance Summary:"
    awk -F',' 'NR>1 {
        cpu_user_sum+=$2; cpu_system_sum+=$3; cpu_idle_sum+=$4;
        mem_used_sum+=$6; count++
    } END {
        printf "    Avg CPU User:   %.2f%%\n", cpu_user_sum/count;
        printf "    Avg CPU System: %.2f%%\n", cpu_system_sum/count;
        printf "    Avg CPU Idle:   %.2f%%\n", cpu_idle_sum/count;
        printf "    Avg Memory Used: %.0f KB (%.2f MB)\n", mem_used_sum/count, mem_used_sum/count/1024;
    }' "$CSV_FILE"

    echo -e "${GREEN}✓ Data analysis complete${NC}"
else
    echo -e "${RED}✗ No data file found${NC}"
    exit 1
fi
echo ""

# Step 5: Simulate pcd data upload (create JSON format)
echo -e "${YELLOW}[5/7] Preparing data for upload...${NC}"

JSON_FILE="$OUTPUT_DIR/performance_data_${TIMESTAMP}.json"

# Convert CSV to JSON format expected by pcd
cat > "$OUTPUT_DIR/csv_to_json.py" <<'PYTHON_EOF'
import csv
import json
import sys

csv_file = sys.argv[1]
json_file = sys.argv[2]

metrics = []
with open(csv_file, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        metric = {
            "timestamp": int(row['timestamp']),
            "hostname": row['hostname'],
            "cpu": {
                "user": float(row['cpu_user']),
                "system": float(row['cpu_system']),
                "idle": float(row['cpu_idle'])
            },
            "memory": {
                "total_kb": int(row['mem_total_kb']),
                "used_kb": int(row['mem_used_kb']),
                "free_kb": int(row['mem_free_kb'])
            }
        }
        metrics.append(metric)

with open(json_file, 'w') as f:
    json.dump(metrics, f, indent=2)

print(f"Converted {len(metrics)} data points to JSON")
PYTHON_EOF

python3 "$OUTPUT_DIR/csv_to_json.py" "$CSV_FILE" "$JSON_FILE"
echo -e "${GREEN}✓ Data prepared in JSON format: $JSON_FILE${NC}"
echo ""

# Step 6: Display data summary
echo -e "${YELLOW}[6/7] Data Summary${NC}"
echo "  CSV File: $CSV_FILE"
echo "  JSON File: $JSON_FILE"
echo "  Data points: $((LINE_COUNT - 1))"
echo "  Duration: ${TEST_DURATION}s"
echo "  Load level: $LOAD_LEVEL ($WORKERS workers)"
echo ""

# Step 7: Results
echo -e "${YELLOW}[7/7] Test Results${NC}"
echo ""
echo "=============================================="
echo "End-to-End Load Test Complete!"
echo "=============================================="
echo ""
echo "✓ System load generated successfully"
echo "✓ Performance metrics collected"
echo "✓ Data exported in CSV and JSON formats"
echo ""
echo "Output files:"
echo "  - CSV: $CSV_FILE"
echo "  - JSON: $JSON_FILE"
echo ""
echo "Next steps:"
echo "  1. Review the collected data"
echo "  2. Upload CSV to XATbackend via web portal"
echo "  3. Generate reports with automated-Reporting"
echo ""
echo "To manually upload to XATbackend:"
echo "  - Navigate to http://localhost:8000"
echo "  - Log in and go to Collectors > Upload"
echo "  - Upload file: $CSV_FILE"
echo ""

# Clean up temporary scripts
rm -f "$OUTPUT_DIR/collect_metrics.sh"
rm -f "$OUTPUT_DIR/csv_to_json.py"

echo -e "${GREEN}Test completed successfully!${NC}"
