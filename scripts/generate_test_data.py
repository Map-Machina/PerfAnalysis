#!/usr/bin/env python3
"""
Generate synthetic performance data for testing PerfAnalysis
Works on any platform (macOS, Linux, Windows)
"""
import csv
import json
import random
import time
import argparse
from datetime import datetime, timedelta
import os
import platform


def generate_cpu_metrics(base_user=25, base_system=10, variation=15):
    """Generate realistic CPU metrics with variation."""
    cpu_user = max(0, min(100, base_user + random.uniform(-variation, variation)))
    cpu_system = max(0, min(100, base_system + random.uniform(-variation/2, variation/2)))
    cpu_idle = max(0, 100 - cpu_user - cpu_system)

    return {
        'user': round(cpu_user, 2),
        'system': round(cpu_system, 2),
        'idle': round(cpu_idle, 2),
        'iowait': round(random.uniform(0, 5), 2)
    }


def generate_memory_metrics(total_mb=16384):
    """Generate realistic memory metrics."""
    total_kb = total_mb * 1024
    # Random memory usage between 40-80%
    usage_pct = random.uniform(0.4, 0.8)
    used_kb = int(total_kb * usage_pct)
    free_kb = total_kb - used_kb
    cached_kb = int(total_kb * random.uniform(0.1, 0.3))

    return {
        'total_kb': total_kb,
        'used_kb': used_kb,
        'free_kb': free_kb,
        'cached_kb': cached_kb
    }


def generate_disk_metrics():
    """Generate disk I/O metrics."""
    return [
        {
            'device': 'sda',
            'read_bytes': random.randint(1000000, 10000000),
            'write_bytes': random.randint(500000, 5000000),
            'read_ops': random.randint(100, 1000),
            'write_ops': random.randint(50, 500)
        }
    ]


def generate_network_metrics():
    """Generate network I/O metrics."""
    return [
        {
            'interface': 'eth0',
            'rx_bytes': random.randint(1000000, 50000000),
            'tx_bytes': random.randint(500000, 25000000),
            'rx_packets': random.randint(1000, 50000),
            'tx_packets': random.randint(500, 25000),
            'rx_errors': random.randint(0, 10),
            'tx_errors': random.randint(0, 5)
        }
    ]


def generate_sample(timestamp, hostname, scenario='normal'):
    """Generate a complete performance sample."""
    # Adjust base values based on scenario
    scenarios = {
        'normal': {'cpu_base': 25, 'cpu_var': 10},
        'light': {'cpu_base': 15, 'cpu_var': 5},
        'medium': {'cpu_base': 40, 'cpu_var': 15},
        'heavy': {'cpu_base': 70, 'cpu_var': 20},
        'stress': {'cpu_base': 95, 'cpu_var': 5}
    }

    config = scenarios.get(scenario, scenarios['normal'])

    cpu = generate_cpu_metrics(config['cpu_base'], 10, config['cpu_var'])
    memory = generate_memory_metrics()
    disks = generate_disk_metrics()
    network = generate_network_metrics()

    return {
        'timestamp': timestamp,
        'hostname': hostname,
        'cpu': cpu,
        'memory': memory,
        'disks': disks,
        'network': network
    }


def export_to_csv(samples, filename):
    """Export samples to CSV format (XATbackend compatible)."""
    with open(filename, 'w', newline='') as f:
        fieldnames = [
            'timestamp', 'hostname',
            'cpu_user', 'cpu_system', 'cpu_idle', 'cpu_iowait',
            'mem_total_kb', 'mem_used_kb', 'mem_free_kb', 'mem_cached_kb',
            'disk_read_bytes', 'disk_write_bytes',
            'net_rx_bytes', 'net_tx_bytes'
        ]

        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        for sample in samples:
            row = {
                'timestamp': sample['timestamp'],
                'hostname': sample['hostname'],
                'cpu_user': sample['cpu']['user'],
                'cpu_system': sample['cpu']['system'],
                'cpu_idle': sample['cpu']['idle'],
                'cpu_iowait': sample['cpu']['iowait'],
                'mem_total_kb': sample['memory']['total_kb'],
                'mem_used_kb': sample['memory']['used_kb'],
                'mem_free_kb': sample['memory']['free_kb'],
                'mem_cached_kb': sample['memory']['cached_kb'],
                'disk_read_bytes': sample['disks'][0]['read_bytes'],
                'disk_write_bytes': sample['disks'][0]['write_bytes'],
                'net_rx_bytes': sample['network'][0]['rx_bytes'],
                'net_tx_bytes': sample['network'][0]['tx_bytes']
            }
            writer.writerow(row)

    return filename


def export_to_json(samples, filename):
    """Export samples to JSON format (pcd compatible)."""
    with open(filename, 'w') as f:
        json.dump(samples, f, indent=2)

    return filename


def print_statistics(samples):
    """Print statistics about generated data."""
    if not samples:
        return

    cpu_users = [s['cpu']['user'] for s in samples]
    cpu_systems = [s['cpu']['system'] for s in samples]
    mem_used = [s['memory']['used_kb'] for s in samples]

    print("\n" + "="*60)
    print("Generated Data Statistics")
    print("="*60)
    print(f"Total Samples:     {len(samples)}")
    print(f"Hostname:          {samples[0]['hostname']}")
    print(f"Time Range:        {datetime.fromtimestamp(samples[0]['timestamp'])} to {datetime.fromtimestamp(samples[-1]['timestamp'])}")
    print(f"\nCPU Metrics:")
    print(f"  Avg User:        {sum(cpu_users)/len(cpu_users):.2f}%")
    print(f"  Avg System:      {sum(cpu_systems)/len(cpu_systems):.2f}%")
    print(f"  Min User:        {min(cpu_users):.2f}%")
    print(f"  Max User:        {max(cpu_users):.2f}%")
    print(f"\nMemory Metrics:")
    print(f"  Avg Used:        {sum(mem_used)/len(mem_used)/1024:.0f} MB")
    print(f"  Total:           {samples[0]['memory']['total_kb']/1024:.0f} MB")
    print("="*60 + "\n")


def main():
    parser = argparse.ArgumentParser(description='Generate synthetic performance data')
    parser.add_argument('--duration', type=int, default=300,
                        help='Duration in seconds (default: 300)')
    parser.add_argument('--interval', type=int, default=5,
                        help='Collection interval in seconds (default: 5)')
    parser.add_argument('--scenario', choices=['light', 'normal', 'medium', 'heavy', 'stress'],
                        default='medium', help='Load scenario (default: medium)')
    parser.add_argument('--hostname', type=str, default=None,
                        help='Hostname (default: system hostname)')
    parser.add_argument('--output-dir', type=str, default='/tmp/perfanalysis_test',
                        help='Output directory (default: /tmp/perfanalysis_test)')
    parser.add_argument('--format', choices=['csv', 'json', 'both'],
                        default='both', help='Output format (default: both)')
    parser.add_argument('--realtime', action='store_true',
                        help='Generate in real-time instead of all at once')

    args = parser.parse_args()

    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)

    # Get hostname
    hostname = args.hostname or platform.node() or 'test-server-01'

    # Generate samples
    samples = []
    num_samples = args.duration // args.interval

    print(f"\nGenerating {num_samples} samples...")
    print(f"  Scenario:       {args.scenario}")
    print(f"  Duration:       {args.duration}s")
    print(f"  Interval:       {args.interval}s")
    print(f"  Hostname:       {hostname}")
    print(f"  Real-time:      {args.realtime}")

    if args.realtime:
        print(f"\nCollecting data in real-time for {args.duration} seconds...")
        start_time = int(time.time())
        for i in range(num_samples):
            timestamp = start_time + (i * args.interval)
            sample = generate_sample(timestamp, hostname, args.scenario)
            samples.append(sample)

            # Show progress
            if (i + 1) % 10 == 0:
                print(f"  Collected {i + 1}/{num_samples} samples... ({(i+1)/num_samples*100:.1f}%)")

            # Sleep until next interval
            if i < num_samples - 1:
                time.sleep(args.interval)
    else:
        # Generate all samples at once with historical timestamps
        start_time = int(time.time()) - args.duration
        for i in range(num_samples):
            timestamp = start_time + (i * args.interval)
            sample = generate_sample(timestamp, hostname, args.scenario)
            samples.append(sample)

            # Show progress
            if (i + 1) % 100 == 0 or (i + 1) == num_samples:
                print(f"  Generated {i + 1}/{num_samples} samples... ({(i+1)/num_samples*100:.1f}%)")

    # Print statistics
    print_statistics(samples)

    # Export to files
    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')

    if args.format in ['csv', 'both']:
        csv_file = os.path.join(args.output_dir, f'performance_data_{timestamp_str}.csv')
        export_to_csv(samples, csv_file)
        print(f"✓ CSV exported:  {csv_file} ({os.path.getsize(csv_file)} bytes)")

    if args.format in ['json', 'both']:
        json_file = os.path.join(args.output_dir, f'performance_data_{timestamp_str}.json')
        export_to_json(samples, json_file)
        print(f"✓ JSON exported: {json_file} ({os.path.getsize(json_file)} bytes)")

    print("\n" + "="*60)
    print("Data generation complete!")
    print("="*60)
    print("\nNext steps:")
    print("  1. Upload CSV to XATbackend via web portal")
    print("  2. Or use the integration test suite to automate upload")
    print("  3. Generate reports with automated-Reporting")
    print("")


if __name__ == '__main__':
    main()
