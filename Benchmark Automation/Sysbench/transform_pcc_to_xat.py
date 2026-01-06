#!/usr/bin/env python3
"""
Transform pcprocess CSV output to XATbackend import format.

pcprocess creates separate CSVs for cpu, memory, disk, and network.
XATbackend expects a single CSV with all metrics combined by timestamp.
"""

import csv
import os
import sys
from collections import defaultdict
from datetime import datetime


def parse_stat_csv(filepath):
    """Parse proc/stat CSV (CPU data)."""
    data = {}
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Skip header comments and individual CPU rows (take aggregate -1 or 0)
            cpu_id = int(row.get('CPU', -1))
            if cpu_id not in [-1, 0]:
                continue

            ts = int(row['#timestamp'])
            if ts not in data:
                data[ts] = {
                    'cpu_user': float(row.get('%usr', 0)),
                    'cpu_system': float(row.get('%system', 0)),
                    'cpu_idle': float(row.get('%idle', 0)),
                    'cpu_iowait': float(row.get('%iowait', 0)),
                    'cpu_steal': float(row.get('%steal', 0)),
                }
    return data


def parse_meminfo_csv(filepath):
    """Parse proc/meminfo CSV (Memory data)."""
    data = {}
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            ts = int(row['#timestamp'])
            data[ts] = {
                'mem_total_kb': int(float(row.get('kbmemfree', 0)) + float(row.get('kbmemused', 0))),
                'mem_used_kb': int(float(row.get('kbmemused', 0))),
                'mem_free_kb': int(float(row.get('kbmemfree', 0))),
                'mem_cached_kb': int(float(row.get('kbcached', 0))),
            }
    return data


def parse_diskstats_csv(filepath, device='sda'):
    """Parse proc/diskstats CSV (Disk data)."""
    data = {}
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            dev = row.get('DEV', '')
            if dev != device:
                continue

            ts = int(row['#timestamp'])
            # bread/s and bwrtn/s are blocks per second (512 bytes per block)
            data[ts] = {
                'disk_read_bytes': int(float(row.get('bread/s', 0)) * 512),
                'disk_write_bytes': int(float(row.get('bwrtn/s', 0)) * 512),
            }
    return data


def parse_netdev_csv(filepath, interface='eth0'):
    """Parse proc/net/dev CSV (Network data)."""
    data = {}
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            iface = row.get('IFACE', '')
            if iface != interface:
                continue

            ts = int(row['#timestamp'])
            # rxkB/s and txkB/s are KB per second
            data[ts] = {
                'net_rx_bytes': int(float(row.get('rxkB/s', 0)) * 1024),
                'net_tx_bytes': int(float(row.get('txkB/s', 0)) * 1024),
            }
    return data


def merge_data(stat_data, mem_data, disk_data, net_data):
    """Merge all data sources by timestamp."""
    all_timestamps = set(stat_data.keys()) | set(mem_data.keys()) | set(disk_data.keys()) | set(net_data.keys())

    merged = []
    for ts in sorted(all_timestamps):
        row = {'timestamp': ts}
        row.update(stat_data.get(ts, {}))
        row.update(mem_data.get(ts, {}))
        row.update(disk_data.get(ts, {}))
        row.update(net_data.get(ts, {}))
        merged.append(row)

    return merged


def transform_pcc_to_xat(csv_dir, output_file, disk_device='sda', net_interface='eth0'):
    """Transform pcprocess output to XATbackend format."""

    # Parse individual CSVs
    stat_file = os.path.join(csv_dir, 'proc', 'stat')
    mem_file = os.path.join(csv_dir, 'proc', 'meminfo')
    disk_file = os.path.join(csv_dir, 'proc', 'diskstats')
    net_file = os.path.join(csv_dir, 'proc', 'net', 'dev')

    stat_data = parse_stat_csv(stat_file) if os.path.exists(stat_file) else {}
    mem_data = parse_meminfo_csv(mem_file) if os.path.exists(mem_file) else {}
    disk_data = parse_diskstats_csv(disk_file, disk_device) if os.path.exists(disk_file) else {}
    net_data = parse_netdev_csv(net_file, net_interface) if os.path.exists(net_file) else {}

    print(f"Parsed {len(stat_data)} CPU records")
    print(f"Parsed {len(mem_data)} memory records")
    print(f"Parsed {len(disk_data)} disk records (device: {disk_device})")
    print(f"Parsed {len(net_data)} network records (interface: {net_interface})")

    # Merge data
    merged = merge_data(stat_data, mem_data, disk_data, net_data)
    print(f"Merged into {len(merged)} combined records")

    # Write output CSV
    fieldnames = [
        'timestamp',
        'cpu_user', 'cpu_system', 'cpu_idle', 'cpu_iowait', 'cpu_steal',
        'mem_total_kb', 'mem_used_kb', 'mem_free_kb', 'mem_cached_kb',
        'disk_read_bytes', 'disk_write_bytes',
        'net_rx_bytes', 'net_tx_bytes'
    ]

    with open(output_file, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(merged)

    print(f"Written to {output_file}")
    return len(merged)


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: transform_pcc_to_xat.py <csv_dir> <output_file> [disk_device] [net_interface]")
        print("Example: transform_pcc_to_xat.py ./results/pcc-test-01/csv ./output.csv sda eth0")
        sys.exit(1)

    csv_dir = sys.argv[1]
    output_file = sys.argv[2]
    disk_device = sys.argv[3] if len(sys.argv) > 3 else 'sda'
    net_interface = sys.argv[4] if len(sys.argv) > 4 else 'eth0'

    transform_pcc_to_xat(csv_dir, output_file, disk_device, net_interface)
