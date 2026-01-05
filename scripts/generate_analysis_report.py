#!/usr/bin/env python3
"""
Generate Analysis Report using automated-Reporting R code

This script:
1. Takes an uploaded CSV file from XATbackend
2. Converts it to /proc format expected by automated-Reporting
3. Runs the R markdown report generation in r-dev container
4. Returns the PDF report path

Usage:
    python generate_analysis_report.py <csv_file_path> <output_dir>
"""

import sys
import os
import csv
import subprocess
import shutil
from pathlib import Path
from datetime import datetime
import tempfile


def convert_csv_to_proc_format(csv_file, output_dir):
    """
    Convert perfcollector2 CSV to sar/iostat-style format expected by automated-Reporting

    CRITICAL: automated-Reporting expects aggregated metrics in sar/iostat format, NOT raw /proc files!

    Input CSV format:
        timestamp,hostname,cpu_user,cpu_system,cpu_idle,cpu_iowait,
        mem_total_kb,mem_free_kb,mem_used_kb,mem_cached_kb,
        disk_read_bytes,disk_write_bytes,
        net_rx_bytes,net_tx_bytes,...

    Output sar/iostat format files:
        - stat: CPU percentages (#site,host,timestamp,CPU,%usr,%nice,%system,%iowait,%steal,%idle)
        - meminfo: Memory metrics (#site,host,timestamp,kbmemfree,kbavail,kbmemused,%memused,...)
        - diskstats: Disk I/O rates (#site,host,timestamp,DEV,tps,rtps,wtps,dtps,bread/s,bwrtn/s,...)
        - net/dev: Network throughput (#site,host,timestamp,IFACE,rxpck/s,txpck/s,rxkB/s,txkB/s,...)
    """

    proc_dir = Path(output_dir) / "proc"
    proc_dir.mkdir(parents=True, exist_ok=True)
    net_dir = proc_dir / "net"
    net_dir.mkdir(parents=True, exist_ok=True)

    # Read input CSV
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    if not rows:
        raise ValueError("CSV file is empty")

    hostname = rows[0].get('hostname', 'unknown')
    site_id = 1

    # Create stat file (CPU percentages in sar format)
    # Format: #site,host,timestamp,CPU,%usr,%nice,%system,%iowait,%steal,%idle
    with open(proc_dir / "stat", 'w') as f:
        f.write("#site,host,timestamp,CPU,%usr,%nice,%system,%iowait,%steal,%idle\n")
        for row in rows:
            cpu_user = float(row['cpu_user'])
            cpu_system = float(row['cpu_system'])
            cpu_idle = float(row['cpu_idle'])
            cpu_iowait = float(row.get('cpu_iowait', 0))

            f.write(f"{site_id},{hostname},{row['timestamp']},-1,{cpu_user},0,{cpu_system},{cpu_iowait},0,{cpu_idle}\n")

    # Create meminfo file (memory metrics in sar format)
    # Format: #site,host,timestamp,kbmemfree,kbavail,kbmemused,%memused,kbbuffers,kbcached,kbcommit,%commit,kbactive,kbinact,kbdirty
    with open(proc_dir / "meminfo", 'w') as f:
        f.write("#site,host,timestamp,kbmemfree,kbavail,kbmemused,%memused,kbbuffers,kbcached,kbcommit,%commit,kbactive,kbinact,kbdirty\n")
        for row in rows:
            mem_total = int(row['mem_total_kb'])
            mem_free = int(row['mem_free_kb'])
            mem_used = int(row['mem_used_kb'])
            mem_cached = int(row.get('mem_cached_kb', 0))

            pct_memused = (mem_used / mem_total * 100) if mem_total > 0 else 0
            pct_commit = 0  # Not available in perfcollector2

            f.write(f"{site_id},{hostname},{row['timestamp']},{mem_free},{mem_free},{mem_used},{pct_memused},0,{mem_cached},0,{pct_commit},0,0,0\n")

    # Create diskstats file (disk I/O in iostat format)
    # Format: #site,host,timestamp,DEV,tps,rtps,wtps,dtps,bread/s,bwrtn/s,bdscd/s
    with open(proc_dir / "diskstats", 'w') as f:
        f.write("#site,host,timestamp,DEV,tps,rtps,wtps,dtps,bread/s,bwrtn/s,bdscd/s\n")

        # Calculate rates between samples
        for i, row in enumerate(rows):
            if i == 0:
                # First row - use zeros for rates
                bread_rate = 0
                bwrtn_rate = 0
            else:
                prev_row = rows[i-1]
                time_delta = int(row['timestamp']) - int(prev_row['timestamp'])
                if time_delta > 0:
                    # Convert bytes to blocks (1 block = 512 bytes) and calculate rate per second
                    bread_rate = (int(row['disk_read_bytes']) - int(prev_row['disk_read_bytes'])) / 512 / time_delta
                    bwrtn_rate = (int(row['disk_write_bytes']) - int(prev_row['disk_write_bytes'])) / 512 / time_delta
                else:
                    bread_rate = 0
                    bwrtn_rate = 0

            # tps (transactions per second) - approximate from rates
            tps = (bread_rate + bwrtn_rate) / 2 if (bread_rate + bwrtn_rate) > 0 else 0

            f.write(f"{site_id},{hostname},{row['timestamp']},sda,{tps},0,0,0,{bread_rate},{bwrtn_rate},0\n")

    # Create net/dev file (network throughput in sar format)
    # Format: #site,host,timestamp,IFACE,rxpck/s,txpck/s,rxkB/s,txkB/s,rxcmp/s,txcmp/s,rxmcst/s,%ifutil
    with open(net_dir / "dev", 'w') as f:
        f.write("#site,host,timestamp,IFACE,rxpck/s,txpck/s,rxkB/s,txkB/s,rxcmp/s,txcmp/s,rxmcst/s,%ifutil\n")

        # Calculate rates between samples
        for i, row in enumerate(rows):
            if i == 0:
                # First row - use zeros for rates
                rxkB_rate = 0
                txkB_rate = 0
            else:
                prev_row = rows[i-1]
                time_delta = int(row['timestamp']) - int(prev_row['timestamp'])
                if time_delta > 0:
                    # Calculate rates per second (convert bytes to KB)
                    rxkB_rate = (int(row['net_rx_bytes']) - int(prev_row['net_rx_bytes'])) / 1024 / time_delta
                    txkB_rate = (int(row['net_tx_bytes']) - int(prev_row['net_tx_bytes'])) / 1024 / time_delta
                else:
                    rxkB_rate = 0
                    txkB_rate = 0

            f.write(f"{site_id},{hostname},{row['timestamp']},eth0,0,0,{rxkB_rate},{txkB_rate},0,0,0,0\n")

    print(f"✓ Converted CSV to sar/iostat format in {proc_dir}")
    return proc_dir


def generate_r_report(proc_dir, machine_name, uuid, output_dir):
    """
    Generate R markdown report using automated-Reporting in r-dev container
    """

    # The r-dev container mounts ./automated-Reporting at /workspace
    # We need to copy the proc data directory to r-dev container
    container_proc_dir = f"/workspace/temp_data/{uuid}/proc"

    try:
        # Copy proc directory to r-dev container
        print(f"✓ Copying proc data to r-dev container...")

        # Create temp_data directory in r-dev container
        mkdir_result = subprocess.run(
            ['docker', 'exec', 'perfanalysis-r-dev', 'mkdir', '-p', f'/workspace/temp_data/{uuid}'],
            capture_output=True,
            text=True
        )

        if mkdir_result.returncode != 0:
            raise RuntimeError(f"Failed to create temp directory: {mkdir_result.stderr}")

        # Copy the entire proc directory
        cp_proc_result = subprocess.run(
            ['docker', 'cp', str(proc_dir), f'perfanalysis-r-dev:/workspace/temp_data/{uuid}/'],
            capture_output=True,
            text=True
        )

        if cp_proc_result.returncode != 0:
            raise RuntimeError(f"Failed to copy proc data to container: {cp_proc_result.stderr}")

        print(f"✓ Proc data copied successfully")

        # Read the original reporting.Rmd file from container and customize it
        print(f"✓ Creating customized reporting.Rmd...")

        # Read original Rmd from container
        read_rmd_result = subprocess.run(
            ['docker', 'exec', 'perfanalysis-r-dev', 'cat', '/workspace/reporting.Rmd'],
            capture_output=True,
            text=True
        )

        if read_rmd_result.returncode != 0:
            raise RuntimeError(f"Failed to read reporting.Rmd: {read_rmd_result.stderr}")

        original_rmd = read_rmd_result.stdout

        # Replace hardcoded values with our actual values
        # The original has these hardcoded values in the selectTheElements chunk:
        # storeVol <- "sda"
        # netIface <- "ens33"
        # machName <- "machine001"
        # UUID <- "0001-001-002"
        # loc <- ("testData/proc/")

        # Replace hardcoded values with our actual values
        # Note: We keep machName as "machine001" to avoid breaking variable name dependencies
        # The R markdown creates variables like "machine001_utilLegend" based on machName
        customized_rmd = original_rmd.replace(
            'storeVol <- "sda"',
            'storeVol <- "sda"  # Customized for current analysis'
        ).replace(
            'netIface <- "ens33"',
            'netIface <- "eth0"  # Customized for current analysis'
        ).replace(
            'UUID <- "0001-001-002"',
            f'UUID <- "{uuid}"  # Customized for current analysis'
        ).replace(
            'loc <- ("testData/proc/")',
            f'loc <- ("{container_proc_dir}/")'
        )

        # DON'T replace machName - keep it as "machine001" to avoid breaking variable name dependencies
        # The R code creates dynamic variable names like {machName}_utilLegend which breaks if we change it

        # Write customized Rmd to temp file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.Rmd', delete=False) as f:
            f.write(customized_rmd)
            temp_rmd_file = f.name

        # Copy customized Rmd to container
        cp_rmd_result = subprocess.run(
            ['docker', 'cp', temp_rmd_file, f'perfanalysis-r-dev:/tmp/reporting_custom_{uuid}.Rmd'],
            capture_output=True,
            text=True
        )

        if cp_rmd_result.returncode != 0:
            raise RuntimeError(f"Failed to copy customized Rmd: {cp_rmd_result.stderr}")

        print(f"✓ Customized Rmd created with uuid={uuid}")
        print(f"✓ Data location: {container_proc_dir}/")
        print(f"✓ Note: machName kept as 'machine001' to preserve R variable naming")

        # Create R script content (simplified - just render the customized Rmd)
        r_script = f"""
# Set working directory
setwd("/workspace")

# Activate renv environment (rmarkdown is installed there)
if (file.exists("renv/activate.R")) {{
    source("renv/activate.R")
}}

# Load required libraries
library(rmarkdown)

# Render the customized report
tryCatch({{
    render(
        "/tmp/reporting_custom_{uuid}.Rmd",
        output_file = "/tmp/report.pdf"
    )
    cat("SUCCESS: Report generated\\n")
}}, error = function(e) {{
    cat("ERROR:", conditionMessage(e), "\\n")
    quit(status = 1)
}})
"""

        # Write R script to temp file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.R', delete=False) as f:
            f.write(r_script)
            temp_r_script = f.name

        # Copy the R script to r-dev container
        print(f"✓ Running R report generation in r-dev container...")

        cp_script_result = subprocess.run(
            ['docker', 'cp', temp_r_script, 'perfanalysis-r-dev:/tmp/generate_report.R'],
            capture_output=True,
            text=True
        )

        if cp_script_result.returncode != 0:
            raise RuntimeError(f"Failed to copy R script to container: {cp_script_result.stderr}")

        # Execute R script in r-dev container with PATH set for TinyTeX
        # Use bash -c to set PATH before running Rscript
        result = subprocess.run(
            ['docker', 'exec', 'perfanalysis-r-dev', 'bash', '-c', 'export PATH=/root/bin:$PATH && Rscript /tmp/generate_report.R'],
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )

        if result.returncode != 0:
            print(f"R script stderr: {result.stderr}")
            print(f"R script stdout: {result.stdout}")
            raise RuntimeError(f"R report generation failed: {result.stderr}")

        print(f"✓ R report generated successfully")
        print(f"R output: {result.stdout}")

        # Copy the generated PDF from r-dev container to output directory
        pdf_path = Path(output_dir) / "report.pdf"

        cp_pdf_result = subprocess.run(
            ['docker', 'cp', 'perfanalysis-r-dev:/tmp/report.pdf', str(pdf_path)],
            capture_output=True,
            text=True
        )

        if cp_pdf_result.returncode != 0:
            raise RuntimeError(f"Failed to copy PDF from container: {cp_pdf_result.stderr}")

        if not pdf_path.exists():
            raise FileNotFoundError(f"Generated PDF not found at {pdf_path}")

        print(f"✓ PDF copied to {pdf_path}")
        return pdf_path

    finally:
        # Clean up temp files on host
        if 'temp_r_script' in locals() and os.path.exists(temp_r_script):
            os.unlink(temp_r_script)
        if 'temp_rmd_file' in locals() and os.path.exists(temp_rmd_file):
            os.unlink(temp_rmd_file)

        # Clean up files in r-dev container
        subprocess.run(
            ['docker', 'exec', 'perfanalysis-r-dev', 'rm', '-rf', f'/workspace/temp_data/{uuid}'],
            capture_output=True
        )
        subprocess.run(
            ['docker', 'exec', 'perfanalysis-r-dev', 'rm', '-f', '/tmp/generate_report.R', '/tmp/report.pdf', f'/tmp/reporting_custom_{uuid}.Rmd'],
            capture_output=True
        )


def main():
    if len(sys.argv) < 3:
        print("Usage: python generate_analysis_report.py <csv_file_path> <output_dir>")
        sys.exit(1)

    csv_file = sys.argv[1]
    output_dir = sys.argv[2]

    # Validate inputs
    if not os.path.exists(csv_file):
        print(f"Error: CSV file not found: {csv_file}")
        sys.exit(1)

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Extract machine name and generate UUID
    machine_name = Path(csv_file).stem
    uuid = datetime.now().strftime("%Y%m%d_%H%M%S")

    print(f"Generating analysis report for {machine_name}")
    print(f"Input CSV: {csv_file}")
    print(f"Output directory: {output_dir}")

    # Step 1: Convert CSV to /proc format
    try:
        proc_dir = convert_csv_to_proc_format(csv_file, output_dir)
    except Exception as e:
        print(f"Error converting CSV: {e}")
        sys.exit(1)

    # Step 2: Generate R report
    try:
        pdf_path = generate_r_report(proc_dir, machine_name, uuid, output_dir)
        print(f"✓ Report successfully generated: {pdf_path}")
        print(str(pdf_path))  # Output path for parent process
    except Exception as e:
        print(f"Error generating R report: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
