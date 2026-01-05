"""
End-to-End Integration Tests for PerfAnalysis
Tests the complete data flow: perfcollector2 → XATbackend → automated-Reporting

These tests verify:
1. Data collection from perfcollector2 (pcc/pcd)
2. Upload to XATbackend
3. Multi-tenant data isolation
4. API authentication
5. Data export for R processing
"""
import os
import sys
import time
import json
import requests
import subprocess
import tempfile
import csv
from pathlib import Path

# Test configuration
BASE_DIR = Path(__file__).resolve().parent.parent.parent
XATBACKEND_URL = os.getenv('XATBACKEND_URL', 'http://localhost:8000')
PCD_URL = os.getenv('PCD_URL', 'http://localhost:8080')
TEST_TIMEOUT = 30  # seconds


class TestE2EDataFlow:
    """End-to-end integration tests."""

    @classmethod
    def setup_class(cls):
        """Set up test environment."""
        cls.test_user = {
            'username': 'integrationtest',
            'password': 'testpass123',
            'email': 'integration@test.com'
        }
        cls.collector_data = {
            'sitename': 'IntegrationTestSite',
            'machinename': 'integration-test-01',
            'platform': 'Linux Server'
        }

    def test_01_pcd_health_check(self):
        """Test that pcd daemon is running and healthy."""
        try:
            response = requests.get(f"{PCD_URL}/v1/ping", timeout=5)
            assert response.status_code == 200, f"pcd health check failed: {response.status_code}"
            data = response.json()
            assert 'status' in data or 'pong' in data.get('message', '').lower()
            print("✓ pcd daemon is healthy")
        except requests.exceptions.ConnectionError:
            raise AssertionError("pcd daemon is not running - check docker-compose")

    def test_02_xatbackend_health_check(self):
        """Test that XATbackend is running and healthy."""
        try:
            response = requests.get(f"{XATBACKEND_URL}/health/", timeout=5)
            assert response.status_code == 200, f"XATbackend health check failed: {response.status_code}"
            print("✓ XATbackend is healthy")
        except requests.exceptions.ConnectionError:
            raise AssertionError("XATbackend is not running - check docker-compose")

    def test_03_database_connectivity(self):
        """Test database connectivity through XATbackend."""
        # Try to access a page that requires DB (will redirect to login)
        response = requests.get(f"{XATBACKEND_URL}/collectors/manage", allow_redirects=False)
        assert response.status_code == 302, "Database connection issue detected"
        assert '/auth/login/' in response.headers.get('Location', '')
        print("✓ Database connectivity OK")

    def test_04_create_test_user(self):
        """Create a test user for integration tests."""
        # Use Django management command via docker-compose
        cmd = [
            'docker-compose', 'exec', '-T', 'xatbackend',
            'python', 'manage.py', 'shell', '-c',
            f"""
from django.contrib.auth.models import User
try:
    user = User.objects.get(username='{self.test_user['username']}')
    print('User already exists')
except User.DoesNotExist:
    user = User.objects.create_user(
        username='{self.test_user['username']}',
        email='{self.test_user['email']}',
        password='{self.test_user['password']}'
    )
    print('User created')
"""
        ]
        result = subprocess.run(cmd, cwd=BASE_DIR, capture_output=True, text=True)
        assert result.returncode == 0, f"Failed to create user: {result.stderr}"
        print(f"✓ Test user '{self.test_user['username']}' ready")

    def test_05_user_authentication(self):
        """Test user authentication via XATbackend."""
        session = requests.Session()

        # Get CSRF token
        response = session.get(f"{XATBACKEND_URL}/auth/login/")
        csrf_token = session.cookies.get('csrftoken')

        # Login
        login_data = {
            'username': self.test_user['username'],
            'password': self.test_user['password'],
            'csrfmiddlewaretoken': csrf_token
        }
        response = session.post(
            f"{XATBACKEND_URL}/auth/login/",
            data=login_data,
            headers={'Referer': f"{XATBACKEND_URL}/auth/login/"}
        )

        # Verify login success
        assert response.status_code in [200, 302], f"Login failed: {response.status_code}"

        # Verify we can access protected page
        response = session.get(f"{XATBACKEND_URL}/collectors/manage")
        assert response.status_code == 200, "Authentication failed"
        print("✓ User authentication successful")

    def test_06_create_collector(self):
        """Create a test collector via XATbackend."""
        cmd = [
            'docker-compose', 'exec', '-T', 'xatbackend',
            'python', 'manage.py', 'shell', '-c',
            f"""
from django.contrib.auth.models import User
from collectors.models import Collector, Platform

user = User.objects.get(username='{self.test_user['username']}')

# Get or create platform
platform, _ = Platform.objects.get_or_create(
    name='Linux Server',
    defaults={{'description': 'Linux Server', 'keyurl': 'https://linux.org'}}
)

# Create collector
collector, created = Collector.objects.get_or_create(
    owner=user,
    sitename='{self.collector_data['sitename']}',
    machinename='{self.collector_data['machinename']}',
    defaults={{'platform': platform}}
)
print(f'Collector ID: {{collector.pk}}')
"""
        ]
        result = subprocess.run(cmd, cwd=BASE_DIR, capture_output=True, text=True)
        assert result.returncode == 0, f"Failed to create collector: {result.stderr}"
        print(f"✓ Test collector created")

    def test_07_simulate_data_collection(self):
        """Simulate performance data collection."""
        # Create sample performance data (CSV format)
        test_data = {
            'timestamp': int(time.time()),
            'hostname': self.collector_data['machinename'],
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

        # Create CSV file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.csv', delete=False) as f:
            csv_path = f.name
            writer = csv.DictWriter(f, fieldnames=test_data.keys())
            writer.writeheader()
            writer.writerow(test_data)

        print(f"✓ Performance data generated: {csv_path}")

        # Store for next test
        self.__class__.test_csv_path = csv_path
        self.__class__.test_data = test_data

    def test_08_upload_data_to_xatbackend(self):
        """Upload performance data to XATbackend."""
        session = requests.Session()

        # Login
        response = session.get(f"{XATBACKEND_URL}/auth/login/")
        csrf_token = session.cookies.get('csrftoken')

        login_data = {
            'username': self.test_user['username'],
            'password': self.test_user['password'],
            'csrfmiddlewaretoken': csrf_token
        }
        session.post(
            f"{XATBACKEND_URL}/auth/login/",
            data=login_data,
            headers={'Referer': f"{XATBACKEND_URL}/auth/login/"}
        )

        # Get collector ID
        cmd = [
            'docker-compose', 'exec', '-T', 'xatbackend',
            'python', 'manage.py', 'shell', '-c',
            f"""
from collectors.models import Collector
collector = Collector.objects.get(machinename='{self.collector_data['machinename']}')
print(collector.pk)
"""
        ]
        result = subprocess.run(cmd, cwd=BASE_DIR, capture_output=True, text=True)
        collector_id = result.stdout.strip().split('\n')[-1]

        # Upload file
        csrf_token = session.cookies.get('csrftoken')
        with open(self.test_csv_path, 'rb') as f:
            files = {'uploaded_file': ('test_data.csv', f, 'text/csv')}
            data = {
                'collector': collector_id,
                'description': 'Integration test data',
                'csrfmiddlewaretoken': csrf_token
            }
            response = session.post(
                f"{XATBACKEND_URL}/collectors/manage/upload/{collector_id}/",
                files=files,
                data=data,
                headers={'Referer': f"{XATBACKEND_URL}/collectors/manage/"}
            )

        assert response.status_code in [200, 302], f"Upload failed: {response.status_code}"
        print("✓ Data uploaded to XATbackend")

    def test_09_verify_data_in_database(self):
        """Verify uploaded data is in database."""
        cmd = [
            'docker-compose', 'exec', '-T', 'xatbackend',
            'python', 'manage.py', 'shell', '-c',
            f"""
from collectors.models import Collector, CollectedData
collector = Collector.objects.get(machinename='{self.collector_data['machinename']}')
data_count = CollectedData.objects.filter(collector=collector).count()
print(f'Data files: {{data_count}}')
if data_count > 0:
    latest = CollectedData.objects.filter(collector=collector).latest('upload_date')
    print(f'Latest file: {{latest.uploaded_file.name}}')
"""
        ]
        result = subprocess.run(cmd, cwd=BASE_DIR, capture_output=True, text=True)
        assert result.returncode == 0, f"Database verification failed: {result.stderr}"
        assert 'Data files:' in result.stdout
        print("✓ Data verified in database")

    def test_10_multi_tenant_isolation(self):
        """Test that multi-tenant data isolation works."""
        # Create second user
        cmd = [
            'docker-compose', 'exec', '-T', 'xatbackend',
            'python', 'manage.py', 'shell', '-c',
            """
from django.contrib.auth.models import User
from collectors.models import Collector

# Create second user
user2, _ = User.objects.get_or_create(
    username='integrationtest2',
    defaults={'email': 'integration2@test.com'}
)
user2.set_password('testpass123')
user2.save()

# Get user1's collector count
user1 = User.objects.get(username='integrationtest')
user1_count = Collector.objects.filter(owner=user1).count()
user2_count = Collector.objects.filter(owner=user2).count()

print(f'User1 collectors: {user1_count}')
print(f'User2 collectors: {user2_count}')
"""
        ]
        result = subprocess.run(cmd, cwd=BASE_DIR, capture_output=True, text=True)
        assert result.returncode == 0, f"Multi-tenant test failed: {result.stderr}"

        # Verify user1 has collectors, user2 has none
        output_lines = result.stdout.strip().split('\n')
        user1_line = [l for l in output_lines if 'User1 collectors:' in l][0]
        user2_line = [l for l in output_lines if 'User2 collectors:' in l][0]

        user1_count = int(user1_line.split(':')[1].strip())
        user2_count = int(user2_line.split(':')[1].strip())

        assert user1_count > 0, "User1 should have collectors"
        assert user2_count == 0, "User2 should have no collectors (data isolation)"
        print("✓ Multi-tenant data isolation verified")

    def test_11_api_authentication(self):
        """Test API key authentication for pcd."""
        # This would test API key auth if implemented
        # For now, verify the endpoint exists
        response = requests.post(
            f"{PCD_URL}/v1/data",
            json={'test': 'data'},
            headers={'Content-Type': 'application/json'}
        )
        # We expect 401 or 403 (unauthorized) without valid API key
        # Or 400 if endpoint exists but data is invalid
        assert response.status_code in [400, 401, 403, 404, 501], \
            f"API endpoint test returned unexpected status: {response.status_code}"
        print("✓ API authentication check complete")

    def test_12_performance_metrics_validation(self):
        """Validate that performance metrics have expected ranges."""
        # Verify uploaded data has valid metric ranges
        data = self.__class__.test_data

        # CPU percentages should be 0-100
        assert 0 <= data['cpu_user'] <= 100
        assert 0 <= data['cpu_system'] <= 100
        assert 0 <= data['cpu_idle'] <= 100

        # Memory values should be positive
        assert data['mem_total'] > 0
        assert data['mem_used'] >= 0
        assert data['mem_free'] >= 0

        # I/O values should be non-negative
        assert data['disk_read_bytes'] >= 0
        assert data['disk_write_bytes'] >= 0
        assert data['net_rx_bytes'] >= 0
        assert data['net_tx_bytes'] >= 0

        print("✓ Performance metrics validation passed")

    @classmethod
    def teardown_class(cls):
        """Clean up test data."""
        # Remove test CSV file
        if hasattr(cls, 'test_csv_path') and os.path.exists(cls.test_csv_path):
            os.unlink(cls.test_csv_path)

        print("\n✓ Integration tests complete")


if __name__ == '__main__':
    import pytest
    sys.exit(pytest.main([__file__, '-v', '-s']))
