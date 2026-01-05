#!/bin/bash
# Simplified End-to-End Demonstration of PerfAnalysis
# This script demonstrates:
# 1. Generate system load data
# 2. Create visualizations with R
# 3. Display results summary

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DURATION=60  # 1 minute
INTERVAL=5   # 5 seconds between samples
SCENARIO="medium"
OUTPUT_DIR="/tmp/perfanalysis_demo"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${CYAN}================================================================"
echo "PerfAnalysis - End-to-End Demonstration"
echo "================================================================${NC}"
echo ""
echo "This demo will:"
echo "  1. Generate synthetic workload (1 minute)"
echo "  2. Create R visualizations"
echo "  3. Display results"
echo ""

mkdir -p "$OUTPUT_DIR"

# =================================================================
# STEP 1: Generate Performance Data
# =================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗"
echo -e "║  STEP 1: Generating Performance Data                  ║"
echo -e "╚════════════════════════════════════════════════════════╝${NC}"

echo -e "${YELLOW}Running data generator for ${DURATION} seconds...${NC}"
python3 scripts/generate_test_data.py \
    --scenario "$SCENARIO" \
    --duration "$DURATION" \
    --interval "$INTERVAL" \
    --output-dir "$OUTPUT_DIR" \
    --format both

CSV_FILE=$(ls -t "$OUTPUT_DIR"/*.csv | head -1)
JSON_FILE=$(ls -t "$OUTPUT_DIR"/*.json | head -1)

echo -e "${GREEN}✓ Data generated:${NC}"
echo "  CSV:  $CSV_FILE"
echo "  JSON: $JSON_FILE"

# =================================================================
# STEP 2: Generate Visualization with R
# =================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗"
echo -e "║  STEP 2: Generating Visualization with R              ║"
echo -e "╚════════════════════════════════════════════════════════╝${NC}"

echo -e "${YELLOW}Creating R visualization script...${NC}"

cat > "$OUTPUT_DIR/visualize.R" <<'R_SCRIPT'
# Load required libraries
if (!require("ggplot2")) install.packages("ggplot2", repos="https://cloud.r-project.org/")
if (!require("data.table")) install.packages("data.table", repos="https://cloud.r-project.org/")

library(ggplot2)
library(data.table)

# Read CSV data
args <- commandArgs(trailingOnly = TRUE)
csv_file <- args[1]
output_dir <- args[2]

cat("Loading data from:", csv_file, "\n")
data <- fread(csv_file)

cat("Data summary:\n")
cat("  Rows:", nrow(data), "\n")
cat("  Columns:", ncol(data), "\n")

# Convert timestamp to datetime if needed
if ("timestamp" %in% names(data)) {
    data$datetime <- as.POSIXct(data$timestamp, origin="1970-01-01")
} else {
    data$datetime <- seq_len(nrow(data))
}

# Create output directory
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# 1. CPU Usage Plot
cat("\nGenerating CPU usage plot...\n")
cpu_plot <- ggplot(data, aes(x = datetime)) +
    geom_line(aes(y = cpu_user, color = "User"), size = 1) +
    geom_line(aes(y = cpu_system, color = "System"), size = 1) +
    geom_line(aes(y = cpu_idle, color = "Idle"), size = 0.5, alpha = 0.5) +
    scale_color_manual(values = c("User" = "#2E86AB", "System" = "#A23B72", "Idle" = "#C1C1C1")) +
    labs(
        title = "CPU Usage Over Time",
        subtitle = paste("Samples:", nrow(data)),
        x = "Time",
        y = "CPU Usage (%)",
        color = "Type"
    ) +
    theme_minimal() +
    theme(
        plot.title = element_text(size = 16, face = "bold"),
        plot.subtitle = element_text(size = 10, color = "gray50"),
        legend.position = "bottom"
    )

ggsave(
    file.path(output_dir, "cpu_usage.png"),
    cpu_plot,
    width = 10,
    height = 6,
    dpi = 300
)
cat("  ✓ Saved: cpu_usage.png\n")

# 2. Memory Usage Plot
cat("\nGenerating memory usage plot...\n")
data$mem_used_mb <- data$mem_used_kb / 1024
data$mem_total_mb <- data$mem_total_kb / 1024

mem_plot <- ggplot(data, aes(x = datetime)) +
    geom_area(aes(y = mem_used_mb), fill = "#FF6B6B", alpha = 0.7) +
    geom_line(aes(y = mem_total_mb), color = "#4ECDC4", size = 1, linetype = "dashed") +
    labs(
        title = "Memory Usage Over Time",
        subtitle = paste("Average Used:", round(mean(data$mem_used_mb), 0), "MB"),
        x = "Time",
        y = "Memory (MB)"
    ) +
    theme_minimal() +
    theme(
        plot.title = element_text(size = 16, face = "bold"),
        plot.subtitle = element_text(size = 10, color = "gray50")
    )

ggsave(
    file.path(output_dir, "memory_usage.png"),
    mem_plot,
    width = 10,
    height = 6,
    dpi = 300
)
cat("  ✓ Saved: memory_usage.png\n")

# 3. Calculate statistics
cat("\nPerformance Statistics:\n")
stats <- data.frame(
    Metric = c("CPU User", "CPU System", "Memory Used"),
    Average = c(
        mean(data$cpu_user),
        mean(data$cpu_system),
        mean(data$mem_used_mb)
    ),
    Max = c(
        max(data$cpu_user),
        max(data$cpu_system),
        max(data$mem_used_mb)
    ),
    Min = c(
        min(data$cpu_user),
        min(data$cpu_system),
        min(data$mem_used_mb)
    )
)

print(stats)

cat("\n✓ All visualizations generated successfully!\n")
cat("  Output directory:", output_dir, "\n")
R_SCRIPT

echo -e "${YELLOW}Running R visualization...${NC}"

# Copy CSV to container and run R script
docker cp "$CSV_FILE" perfanalysis-r-dev:/tmp/data.csv
docker cp "$OUTPUT_DIR/visualize.R" perfanalysis-r-dev:/tmp/visualize.R

mkdir -p "$OUTPUT_DIR/visualizations"

docker-compose exec -T r-dev Rscript /tmp/visualize.R /tmp/data.csv /tmp/visualizations

# Copy visualizations back
docker cp perfanalysis-r-dev:/tmp/visualizations/cpu_usage.png "$OUTPUT_DIR/visualizations/"
docker cp perfanalysis-r-dev:/tmp/visualizations/memory_usage.png "$OUTPUT_DIR/visualizations/"

echo -e "${GREEN}✓ Visualizations created${NC}"
echo "  Location: $OUTPUT_DIR/visualizations/"
ls -lh "$OUTPUT_DIR/visualizations/"

# =================================================================
# STEP 3: Display Results Summary
# =================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════╗"
echo -e "║  STEP 3: Results Summary                               ║"
echo -e "╚════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}  END-TO-END DEMO COMPLETE!${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}📊 Generated Data:${NC}"
echo "  • CSV File: $CSV_FILE"
echo "  • JSON File: $JSON_FILE"
echo "  • Samples: $(wc -l < "$CSV_FILE") data points"

echo -e "\n${CYAN}📈 Visualizations:${NC}"
echo "  • CPU Usage: $OUTPUT_DIR/visualizations/cpu_usage.png"
echo "  • Memory Usage: $OUTPUT_DIR/visualizations/memory_usage.png"

echo -e "\n${CYAN}📋 Quick Statistics:${NC}"
# Calculate and display statistics
python3 <<STATS
import csv

with open("$CSV_FILE", 'r') as f:
    reader = csv.DictReader(f)
    rows = list(reader)

cpu_user = [float(r['cpu_user']) for r in rows]
cpu_system = [float(r['cpu_system']) for r in rows]
mem_used = [int(r['mem_used_kb']) for r in rows]

print(f"  • Avg CPU User:   {sum(cpu_user)/len(cpu_user):.2f}%")
print(f"  • Max CPU User:   {max(cpu_user):.2f}%")
print(f"  • Avg CPU System: {sum(cpu_system)/len(cpu_system):.2f}%")
print(f"  • Avg Memory:     {sum(mem_used)/len(mem_used)/1024:.0f} MB")
STATS

echo -e "\n${CYAN}🌐 Portal Upload Instructions:${NC}"
echo "  1. Open portal: http://localhost:8000/auth/login/"
echo "  2. Login with: admin@perfanalysis.com / admin123"
echo "  3. Navigate to: Collectors > Manage"
echo "  4. Select or create collector: demo-server-01"
echo "  5. Upload file: $CSV_FILE"

echo -e "\n${GREEN}✓ Complete end-to-end workflow demonstrated successfully!${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "  1. View visualizations:"
echo "     open $OUTPUT_DIR/visualizations/cpu_usage.png"
echo "     open $OUTPUT_DIR/visualizations/memory_usage.png"
echo ""
echo "  2. Upload to portal:"
echo "     File location: $CSV_FILE"
echo "     Portal URL: http://localhost:8000/collectors/manage"
echo ""

echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
