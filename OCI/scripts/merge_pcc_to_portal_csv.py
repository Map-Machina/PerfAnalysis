#!/usr/bin/env python3
"""
Merge pcprocess output files into a single CSV for XATbackend portal.

Portal expects:
timestamp,cpu_user,cpu_system,cpu_idle,cpu_iowait,cpu_steal,mem_total_kb,mem_used_kb,mem_free_kb,mem_cached_kb,disk_read_bytes,disk_write_bytes,net_rx_bytes,net_tx_bytes
"""

import csv
import sys
import os
from collections import defaultdict

def read_csv_to_dict(filepath):
    """Read a CSV file and return dict keyed by timestamp."""
    data = defaultdict(list)
    if not os.path.exists(filepath):
        print(f"Warning: {filepath} not found", file=sys.stderr)
        return data

    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Handle both #timestamp and timestamp column names
            ts = row.get('#timestamp') or row.get('timestamp')
            if ts:
                data[ts].append(row)
    return data

def merge_pcc_data(input_dir, output_file):
    """Merge pcprocess output files into portal CSV format."""

    # Read all input files
    stat_data = read_csv_to_dict(os.path.join(input_dir, 'proc', 'stat'))
    mem_data = read_csv_to_dict(os.path.join(input_dir, 'proc', 'meminfo'))
    disk_data = read_csv_to_dict(os.path.join(input_dir, 'proc', 'diskstats'))
    net_data = read_csv_to_dict(os.path.join(input_dir, 'proc', 'net', 'dev'))

    # Get all timestamps (use stat as primary since it has CPU data)
    all_timestamps = set()
    for data in [stat_data, mem_data, disk_data, net_data]:
        all_timestamps.update(data.keys())

    # Filter stat to only include aggregate CPU (CPU=-1)
    stat_aggregate = {}
    for ts, rows in stat_data.items():
        for row in rows:
            if row.get('CPU') == '-1':
                stat_aggregate[ts] = row
                break

    # Filter disk to primary device (sda, usually first non-partition)
    disk_primary = {}
    for ts, rows in disk_data.items():
        for row in rows:
            dev = row.get('DEV', '')
            if dev in ('sda', 'vda', 'nvme0n1'):
                disk_primary[ts] = row
                break

    # Filter network to primary interface (not lo)
    net_primary = {}
    for ts, rows in net_data.items():
        for row in rows:
            iface = row.get('IFACE', '')
            if iface and iface != 'lo':
                net_primary[ts] = row
                break

    # For mem_data, just take the first row for each timestamp
    mem_single = {ts: rows[0] for ts, rows in mem_data.items() if rows}

    # Get common timestamps
    timestamps = sorted(set(stat_aggregate.keys()) & set(mem_single.keys()))

    if not timestamps:
        print("Error: No matching timestamps found", file=sys.stderr)
        return False

    print(f"Found {len(timestamps)} data points", file=sys.stderr)

    # Write merged CSV
    with open(output_file, 'w', newline='') as f:
        fieldnames = [
            'timestamp', 'cpu_user', 'cpu_system', 'cpu_idle', 'cpu_iowait', 'cpu_steal',
            'mem_total_kb', 'mem_used_kb', 'mem_free_kb', 'mem_cached_kb',
            'disk_read_bytes', 'disk_write_bytes', 'net_rx_bytes', 'net_tx_bytes'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        for ts in timestamps:
            stat = stat_aggregate.get(ts, {})
            mem = mem_single.get(ts, {})
            disk = disk_primary.get(ts, {})
            net = net_primary.get(ts, {})

            # Calculate mem_total from memfree + memused (or use a constant if known)
            mem_free = float(mem.get('kbmemfree', 0))
            mem_used = float(mem.get('kbmemused', 0))
            mem_total = mem_free + mem_used + float(mem.get('kbbuffers', 0)) + float(mem.get('kbcached', 0))

            # Convert disk read/write from blocks/s to bytes (assuming 512-byte blocks)
            disk_read = float(disk.get('bread/s', 0)) * 512
            disk_write = float(disk.get('bwrtn/s', 0)) * 512

            # Convert network from KB/s to bytes
            net_rx = float(net.get('rxkB/s', 0)) * 1024
            net_tx = float(net.get('txkB/s', 0)) * 1024

            row = {
                'timestamp': ts,
                'cpu_user': stat.get('%usr', 0),
                'cpu_system': stat.get('%system', 0),
                'cpu_idle': stat.get('%idle', 0),
                'cpu_iowait': stat.get('%iowait', 0),
                'cpu_steal': stat.get('%steal', 0),
                'mem_total_kb': int(mem_total),
                'mem_used_kb': int(mem_used),
                'mem_free_kb': int(mem_free),
                'mem_cached_kb': int(float(mem.get('kbcached', 0))),
                'disk_read_bytes': int(disk_read),
                'disk_write_bytes': int(disk_write),
                'net_rx_bytes': int(net_rx),
                'net_tx_bytes': int(net_tx)
            }
            writer.writerow(row)

    print(f"Wrote {output_file}", file=sys.stderr)
    return True

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input_dir> <output_csv>", file=sys.stderr)
        sys.exit(1)

    input_dir = sys.argv[1]
    output_file = sys.argv[2]

    if merge_pcc_data(input_dir, output_file):
        print(f"Successfully created {output_file}")
    else:
        sys.exit(1)
