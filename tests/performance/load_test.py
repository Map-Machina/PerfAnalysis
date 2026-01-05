#!/usr/bin/env python3
"""
Load Testing Script for PerfAnalysis
Tests system performance under various load conditions

Usage:
    python load_test.py --scenario light
    python load_test.py --scenario medium
    python load_test.py --scenario heavy
    python load_test.py --scenario stress
"""
import argparse
import asyncio
import aiohttp
import time
import json
import csv
import tempfile
import statistics
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Tuple


class LoadTestConfig:
    """Configuration for different load scenarios."""

    SCENARIOS = {
        'light': {
            'concurrent_users': 5,
            'requests_per_user': 20,
            'upload_interval': 2.0,  # seconds
            'description': 'Light load - 5 users, 20 requests each'
        },
        'medium': {
            'concurrent_users': 20,
            'requests_per_user': 50,
            'upload_interval': 1.0,
            'description': 'Medium load - 20 users, 50 requests each'
        },
        'heavy': {
            'concurrent_users': 50,
            'requests_per_user': 100,
            'upload_interval': 0.5,
            'description': 'Heavy load - 50 users, 100 requests each'
        },
        'stress': {
            'concurrent_users': 100,
            'requests_per_user': 200,
            'upload_interval': 0.1,
            'description': 'Stress test - 100 users, 200 requests each'
        }
    }


class PerformanceMetrics:
    """Track performance metrics during load test."""

    def __init__(self):
        self.response_times: List[float] = []
        self.success_count: int = 0
        self.error_count: int = 0
        self.timeout_count: int = 0
        self.start_time: float = 0
        self.end_time: float = 0

    def record_success(self, response_time: float):
        """Record successful request."""
        self.response_times.append(response_time)
        self.success_count += 1

    def record_error(self):
        """Record failed request."""
        self.error_count += 1

    def record_timeout(self):
        """Record timeout."""
        self.timeout_count += 1

    def get_statistics(self) -> Dict:
        """Calculate and return statistics."""
        if not self.response_times:
            return {
                'total_requests': 0,
                'success_count': 0,
                'error_count': 0,
                'timeout_count': 0
            }

        duration = self.end_time - self.start_time
        total_requests = self.success_count + self.error_count + self.timeout_count

        return {
            'total_requests': total_requests,
            'success_count': self.success_count,
            'error_count': self.error_count,
            'timeout_count': self.timeout_count,
            'success_rate': (self.success_count / total_requests * 100) if total_requests > 0 else 0,
            'duration_seconds': duration,
            'requests_per_second': total_requests / duration if duration > 0 else 0,
            'avg_response_time': statistics.mean(self.response_times),
            'median_response_time': statistics.median(self.response_times),
            'min_response_time': min(self.response_times),
            'max_response_time': max(self.response_times),
            'p95_response_time': statistics.quantiles(self.response_times, n=20)[18],  # 95th percentile
            'p99_response_time': statistics.quantiles(self.response_times, n=100)[98],  # 99th percentile
        }


class LoadTester:
    """Main load testing class."""

    def __init__(self, xatbackend_url: str = 'http://localhost:8000'):
        self.xatbackend_url = xatbackend_url
        self.metrics = PerformanceMetrics()

    def generate_sample_data(self) -> str:
        """Generate sample CSV performance data."""
        timestamp = int(time.time())
        data = {
            'timestamp': timestamp,
            'hostname': f'loadtest-{timestamp}',
            'cpu_user': 25.5,
            'cpu_system': 10.2,
            'cpu_idle': 64.3,
            'mem_total': 16777216,
            'mem_used': 8388608,
            'mem_free': 8388608,
            'disk_read_bytes': 1048576,
            'disk_write_bytes': 2097152,
            'net_rx_bytes': 4194304,
            'net_tx_bytes': 2097152
        }

        # Create temporary CSV file
        tmpfile = tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False)
        writer = csv.DictWriter(tmpfile, fieldnames=data.keys())
        writer.writeheader()
        writer.writerow(data)
        tmpfile.close()

        return tmpfile.name

    async def health_check(self, session: aiohttp.ClientSession) -> bool:
        """Check if XATbackend is healthy."""
        try:
            async with session.get(f"{self.xatbackend_url}/health/", timeout=5) as response:
                return response.status == 200
        except Exception:
            return False

    async def simulate_user_session(
        self,
        session: aiohttp.ClientSession,
        user_id: int,
        num_requests: int,
        interval: float
    ):
        """Simulate a user session with multiple requests."""
        for i in range(num_requests):
            start_time = time.time()

            try:
                # Simulate various endpoints
                endpoints = [
                    '/health/',
                    '/collectors/manage',
                    '/auth/login/'
                ]
                endpoint = endpoints[i % len(endpoints)]

                async with session.get(
                    f"{self.xatbackend_url}{endpoint}",
                    allow_redirects=False,
                    timeout=aiohttp.ClientTimeout(total=10)
                ) as response:
                    response_time = time.time() - start_time

                    if response.status in [200, 302]:
                        self.metrics.record_success(response_time)
                    else:
                        self.metrics.record_error()

            except asyncio.TimeoutError:
                self.metrics.record_timeout()
            except Exception:
                self.metrics.record_error()

            # Wait before next request
            if i < num_requests - 1:
                await asyncio.sleep(interval)

    async def run_scenario(self, scenario_name: str):
        """Run a specific load test scenario."""
        if scenario_name not in LoadTestConfig.SCENARIOS:
            raise ValueError(f"Unknown scenario: {scenario_name}")

        config = LoadTestConfig.SCENARIOS[scenario_name]
        print(f"\n{'='*70}")
        print(f"Load Test Scenario: {scenario_name.upper()}")
        print(f"Description: {config['description']}")
        print(f"Concurrent Users: {config['concurrent_users']}")
        print(f"Requests per User: {config['requests_per_user']}")
        print(f"{'='*70}\n")

        # Create session
        async with aiohttp.ClientSession() as session:
            # Health check
            print("Performing health check...")
            if not await self.health_check(session):
                print("❌ Health check failed - XATbackend may not be running")
                return

            print("✓ Health check passed\n")

            # Start load test
            print(f"Starting load test at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            self.metrics.start_time = time.time()

            # Create tasks for concurrent users
            tasks = []
            for user_id in range(config['concurrent_users']):
                task = self.simulate_user_session(
                    session,
                    user_id,
                    config['requests_per_user'],
                    config['upload_interval']
                )
                tasks.append(task)

            # Run all user sessions concurrently
            await asyncio.gather(*tasks)

            self.metrics.end_time = time.time()

            # Print results
            self.print_results()

    def print_results(self):
        """Print load test results."""
        stats = self.metrics.get_statistics()

        print(f"\n{'='*70}")
        print("LOAD TEST RESULTS")
        print(f"{'='*70}")
        print(f"Total Requests:        {stats['total_requests']:,}")
        print(f"Successful:            {stats['success_count']:,} ({stats['success_rate']:.2f}%)")
        print(f"Errors:                {stats['error_count']:,}")
        print(f"Timeouts:              {stats['timeout_count']:,}")
        print(f"\nDuration:              {stats['duration_seconds']:.2f} seconds")
        print(f"Requests/Second:       {stats['requests_per_second']:.2f}")
        print(f"\nResponse Time Statistics (seconds):")
        print(f"  Average:             {stats['avg_response_time']:.4f}")
        print(f"  Median:              {stats['median_response_time']:.4f}")
        print(f"  Min:                 {stats['min_response_time']:.4f}")
        print(f"  Max:                 {stats['max_response_time']:.4f}")
        print(f"  95th Percentile:     {stats['p95_response_time']:.4f}")
        print(f"  99th Percentile:     {stats['p99_response_time']:.4f}")
        print(f"{'='*70}\n")

        # Performance assessment
        self.assess_performance(stats)

    def assess_performance(self, stats: Dict):
        """Assess performance and provide recommendations."""
        print("PERFORMANCE ASSESSMENT")
        print(f"{'='*70}")

        issues = []
        recommendations = []

        # Check success rate
        if stats['success_rate'] < 95:
            issues.append(f"Low success rate: {stats['success_rate']:.2f}%")
            recommendations.append("Investigate error logs and increase resource allocation")

        # Check response times
        if stats['avg_response_time'] > 1.0:
            issues.append(f"High average response time: {stats['avg_response_time']:.2f}s")
            recommendations.append("Consider caching, database indexing, or horizontal scaling")

        if stats['p95_response_time'] > 2.0:
            issues.append(f"High 95th percentile: {stats['p95_response_time']:.2f}s")
            recommendations.append("Optimize slow queries and add database connection pooling")

        # Check throughput
        if stats['requests_per_second'] < 10:
            issues.append(f"Low throughput: {stats['requests_per_second']:.2f} req/s")
            recommendations.append("Review application bottlenecks and consider async processing")

        if issues:
            print("⚠️  Issues Detected:")
            for issue in issues:
                print(f"  - {issue}")
            print("\n💡 Recommendations:")
            for rec in recommendations:
                print(f"  - {rec}")
        else:
            print("✓ Performance is within acceptable ranges")

        print(f"{'='*70}\n")


async def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='PerfAnalysis Load Testing')
    parser.add_argument(
        '--scenario',
        choices=['light', 'medium', 'heavy', 'stress'],
        default='light',
        help='Load test scenario to run'
    )
    parser.add_argument(
        '--url',
        default='http://localhost:8000',
        help='XATbackend URL'
    )

    args = parser.parse_args()

    tester = LoadTester(xatbackend_url=args.url)
    await tester.run_scenario(args.scenario)


if __name__ == '__main__':
    asyncio.run(main())
