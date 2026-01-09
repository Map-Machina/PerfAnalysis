#!/usr/bin/env python3
"""
Convert pcc-container-linux JSON output to CSV format for portal import.

Input JSON format (one object per line):
{"timestamp":1767893329,"subsystem":"container/docker/7892fa5ced3d",
 "measurement":"{\"container_id\":\"...\",\"cpu_usage_usec\":...,\"memory_current\":...}"}

Output CSV format:
timestamp,container_id,container_name,runtime,cpu_percent,cpu_user_percent,cpu_system_percent,
memory_current_bytes,memory_max_bytes,memory_percent,io_read_bytes,io_write_bytes,
io_read_ops,io_write_ops,pids_current
"""

import json
import csv
import sys
from collections import defaultdict


def get_container_name_mapping(docker_host):
    """Get container ID to name mapping by querying docker."""
    # This would be nice to have but for now we'll use empty names
    return {}


def calculate_cpu_percent(current, previous, time_delta_sec):
    """Calculate CPU percentage from usage delta."""
    if not previous or time_delta_sec <= 0:
        return None

    # cpu_usage_usec is cumulative microseconds of CPU time
    cpu_delta = current.get('cpu_usage_usec', 0) - previous.get('cpu_usage_usec', 0)

    # Convert to percentage (1 core = 100%)
    # cpu_delta is in microseconds, time_delta is in seconds
    # So: (cpu_delta / 1e6) / time_delta * 100 = cpu_delta / (time_delta * 1e4)
    cpu_percent = (cpu_delta / 1e6) / time_delta_sec * 100

    return min(cpu_percent, 800)  # Cap at 800% (8 cores)


def calculate_cpu_user_percent(current, previous, time_delta_sec):
    """Calculate user CPU percentage."""
    if not previous or time_delta_sec <= 0:
        return None

    cpu_delta = current.get('cpu_user_usec', 0) - previous.get('cpu_user_usec', 0)
    cpu_percent = (cpu_delta / 1e6) / time_delta_sec * 100

    return min(cpu_percent, 800)


def calculate_cpu_system_percent(current, previous, time_delta_sec):
    """Calculate system CPU percentage."""
    if not previous or time_delta_sec <= 0:
        return None

    cpu_delta = current.get('cpu_system_usec', 0) - previous.get('cpu_system_usec', 0)
    cpu_percent = (cpu_delta / 1e6) / time_delta_sec * 100

    return min(cpu_percent, 800)


def convert_json_to_csv(input_file, output_file, container_names=None):
    """Convert pcc-container JSON to portal CSV format."""
    if container_names is None:
        container_names = {}

    # Read all data, grouped by container
    container_data = defaultdict(list)

    with open(input_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            try:
                record = json.loads(line)
                timestamp = record.get('timestamp')
                subsystem = record.get('subsystem', '')
                measurement_str = record.get('measurement', '{}')

                # Parse the nested measurement JSON
                measurement = json.loads(measurement_str)

                # Extract container ID from subsystem (e.g., "container/docker/7892fa5ced3d")
                parts = subsystem.split('/')
                if len(parts) >= 3:
                    runtime = parts[1]  # docker, containerd, etc.
                    container_id_short = parts[2]
                else:
                    continue

                # Use full container_id from measurement if available
                container_id = measurement.get('container_id', container_id_short)

                container_data[container_id].append({
                    'timestamp': timestamp,
                    'runtime': runtime,
                    'measurement': measurement
                })

            except (json.JSONDecodeError, KeyError) as e:
                print(f"Warning: Skipping invalid line: {e}", file=sys.stderr)
                continue

    # Sort each container's data by timestamp
    for container_id in container_data:
        container_data[container_id].sort(key=lambda x: x['timestamp'])

    # Write CSV with calculated metrics
    with open(output_file, 'w', newline='') as f:
        fieldnames = [
            'timestamp', 'container_id', 'container_name', 'runtime',
            'cpu_percent', 'cpu_user_percent', 'cpu_system_percent',
            'memory_current_bytes', 'memory_max_bytes', 'memory_percent',
            'io_read_bytes', 'io_write_bytes', 'io_read_ops', 'io_write_ops',
            'pids_current'
        ]
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        total_rows = 0

        for container_id, records in container_data.items():
            # Get container name (short ID if not available)
            container_name = container_names.get(container_id, container_id[:12])

            previous = None
            previous_ts = None

            for record in records:
                timestamp = record['timestamp']
                runtime = record['runtime']
                m = record['measurement']

                # Calculate time delta for CPU percentage
                time_delta = 0
                if previous_ts:
                    time_delta = timestamp - previous_ts

                # Calculate CPU percentages
                cpu_percent = calculate_cpu_percent(m, previous, time_delta)
                cpu_user = calculate_cpu_user_percent(m, previous, time_delta)
                cpu_system = calculate_cpu_system_percent(m, previous, time_delta)

                # Memory metrics
                memory_current = m.get('memory_current', 0)
                memory_max = m.get('memory_max', 0)
                memory_percent = (memory_current / memory_max * 100) if memory_max > 0 else 0

                row = {
                    'timestamp': timestamp,
                    'container_id': container_id,
                    'container_name': container_name,
                    'runtime': runtime,
                    'cpu_percent': f'{cpu_percent:.2f}' if cpu_percent is not None else '',
                    'cpu_user_percent': f'{cpu_user:.2f}' if cpu_user is not None else '',
                    'cpu_system_percent': f'{cpu_system:.2f}' if cpu_system is not None else '',
                    'memory_current_bytes': memory_current,
                    'memory_max_bytes': memory_max,
                    'memory_percent': f'{memory_percent:.2f}',
                    'io_read_bytes': m.get('io_read_bytes', 0),
                    'io_write_bytes': m.get('io_write_bytes', 0),
                    'io_read_ops': m.get('io_read_ops', 0),
                    'io_write_ops': m.get('io_write_ops', 0),
                    'pids_current': m.get('pids_current', 0)
                }
                writer.writerow(row)
                total_rows += 1

                previous = m
                previous_ts = timestamp

        print(f"Converted {total_rows} records from {len(container_data)} containers",
              file=sys.stderr)

    return total_rows


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input_json> <output_csv> [container_names.json]",
              file=sys.stderr)
        print("\nOptional container_names.json format:", file=sys.stderr)
        print('{"container_id": "friendly_name", ...}', file=sys.stderr)
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    # Optional container name mapping
    container_names = {}
    if len(sys.argv) > 3:
        with open(sys.argv[3], 'r') as f:
            container_names = json.load(f)

    convert_json_to_csv(input_file, output_file, container_names)
    print(f"Created {output_file}")
