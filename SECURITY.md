# PerfAnalysis Security Architecture

**Version**: 1.0
**Date**: 2026-01-05
**Classification**: Internal
**Agent Assignment**: Security Architect

---

## Table of Contents

1. [Security Overview](#security-overview)
2. [Threat Model](#threat-model)
3. [Authentication & Authorization](#authentication--authorization)
4. [Data Security](#data-security)
5. [Network Security](#network-security)
6. [Security Best Practices](#security-best-practices)
7. [Incident Response](#incident-response)
8. [Compliance](#compliance)

---

## 1. Security Overview

### 1.1 Security Principles

PerfAnalysis follows these core security principles:

1. **Defense in Depth**: Multiple layers of security controls
2. **Least Privilege**: Minimal access rights for users and systems
3. **Secure by Default**: Secure configurations out of the box
4. **Data Isolation**: Strict tenant separation at all layers
5. **Audit Everything**: Comprehensive logging of security events

### 1.2 Security Domains

```
┌─────────────────────────────────────────────────────────────────┐
│                     SECURITY DOMAINS                             │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│   COLLECTION     │   │   APPLICATION    │   │   DATA STORAGE   │
│    SECURITY      │   │    SECURITY      │   │    SECURITY      │
├──────────────────┤   ├──────────────────┤   ├──────────────────┤
│ • API Keys       │   │ • Django Auth    │   │ • Schema         │
│ • TLS Transport  │   │ • Session Mgmt   │   │   Isolation      │
│ • IP Whitelist   │   │ • CSRF Protection│   │ • Encryption     │
│ • Rate Limiting  │   │ • Input Valid.   │   │ • Access Control │
└──────────────────┘   └──────────────────┘   └──────────────────┘
```

---

## 2. Threat Model

### 2.1 Assets

**Critical Assets**:
1. Performance metrics data (confidential business information)
2. User credentials and session tokens
3. API keys for machine-to-machine authentication
4. Database credentials and connection strings
5. Application source code and configuration

**Asset Classification**:
| Asset | Confidentiality | Integrity | Availability |
|-------|-----------------|-----------|--------------|
| Performance Data | HIGH | HIGH | MEDIUM |
| User Credentials | CRITICAL | CRITICAL | HIGH |
| API Keys | HIGH | HIGH | MEDIUM |
| Source Code | MEDIUM | HIGH | LOW |

### 2.2 Threat Actors

1. **External Attackers**:
   - Motivation: Data theft, service disruption
   - Capabilities: OWASP Top 10 exploits, DDoS

2. **Malicious Insiders**:
   - Motivation: Data exfiltration, sabotage
   - Capabilities: Authorized access, system knowledge

3. **Tenant Abuse**:
   - Motivation: Access other tenants' data
   - Capabilities: Legitimate account, application knowledge

### 2.3 Attack Scenarios

#### Scenario 1: Unauthorized Data Access (Cross-Tenant)

**Attack Vector**: Exploit tenant isolation vulnerability to access another organization's data

**Mitigations**:
- PostgreSQL schema-level isolation
- Tenant middleware validation on every request
- URL-based tenant resolution (subdomain)
- No shared tables between tenants
- Automated testing for tenant isolation

**Risk**: LOW (multiple controls in place)

#### Scenario 2: API Key Compromise

**Attack Vector**: Stolen API key used to upload malicious data or extract legitimate data

**Mitigations**:
- API key hashing (bcrypt) - not stored in plaintext
- Key rotation capability
- Rate limiting on upload endpoint
- IP whitelisting (optional)
- Audit logging of all API key usage

**Risk**: MEDIUM (requires key rotation process)

#### Scenario 3: SQL Injection

**Attack Vector**: Malicious SQL in user input to extract/modify database data

**Mitigations**:
- Django ORM (parameterized queries by default)
- Input validation and sanitization
- PostgreSQL permissions (app user cannot DROP tables)
- Web Application Firewall (WAF) in production

**Risk**: LOW (Django ORM protection)

#### Scenario 4: CSV Injection (Upload)

**Attack Vector**: Malicious CSV content containing formulas executed in Excel/LibreOffice

**Mitigations**:
- CSV content validation (reject formulas starting with =, +, -, @)
- Sanitize output when exporting
- Content-Disposition: attachment header
- Content-Type: text/plain for downloads

**Risk**: MEDIUM (requires output sanitization)

#### Scenario 5: DDoS Attack

**Attack Vector**: Flood API endpoints to cause service unavailability

**Mitigations**:
- Rate limiting (django-ratelimit): 100 req/min per IP
- CloudFlare/Azure Front Door DDoS protection
- Connection pooling limits
- Auto-scaling (Azure App Service)

**Risk**: MEDIUM (production mitigations not yet deployed)

---

## 3. Authentication & Authorization

### 3.1 Authentication Methods

#### Machine Authentication (perfcollector2 → XATbackend)

**API Key Generation**:
```python
import secrets
import hashlib

def generate_api_key():
    """Generate a secure API key."""
    # 256-bit random key
    key = secrets.token_urlsafe(32)
    return key

def hash_api_key(api_key):
    """Hash API key for storage."""
    from django.contrib.auth.hashers import make_password
    return make_password(api_key, salt=None, hasher='pbkdf2_sha256')

def verify_api_key(provided_key, stored_hash):
    """Verify provided API key against stored hash."""
    from django.contrib.auth.hashers import check_password
    return check_password(provided_key, stored_hash)
```

**Request Format**:
```http
POST /api/v1/performance/upload HTTP/1.1
Host: tenant1.perfanalysis.example.com
Authorization: Bearer mZlhRVNOZGxKdEJMR2xYRzBXQktGcXpGOGtEOGt...
Content-Type: multipart/form-data
```

**Key Rotation Process**:
1. Generate new API key in portal
2. Update collector configuration with new key
3. Test upload with new key
4. Deactivate old key (grace period: 24 hours)

#### User Authentication (Web Portal)

**Django Authentication**:
- Username/email + password
- Password hashing: PBKDF2-SHA256 (Django default)
- Minimum password strength: 8 characters, mixed case, numbers
- Session timeout: 30 minutes of inactivity
- HTTPS-only session cookies

**Password Policy**:
```python
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
        'OPTIONS': {'min_length': 8}
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]
```

**Optional: Multi-Factor Authentication (MFA)**:
- TOTP (Time-based One-Time Password) via django-otp
- SMS verification (via Twilio/Azure Communication Services)
- Enforced for admin users

### 3.2 Authorization Model

#### Role-Based Access Control (RBAC)

**Tenant-Level Roles**:

| Role | Permissions | Use Case |
|------|-------------|----------|
| **Tenant Admin** | Full tenant access | IT managers |
| | • Manage users | |
| | • Manage collectors | |
| | • View/export all data | |
| | • Generate reports | |
| **Analyst** | Read-only data access | Performance analysts |
| | • View all data | |
| | • Generate reports | |
| | • Export data | |
| **Viewer** | Limited read access | Management |
| | • View dashboards | |
| | • View pre-generated reports | |
| **Collector** | API-only (non-human) | Collector machines |
| | • Upload performance data | |

**Permission Enforcement**:
```python
from django.contrib.auth.decorators import permission_required

@permission_required('collectors.add_collector', raise_exception=True)
def register_collector(request):
    # Only Tenant Admins can register collectors
    pass

@permission_required('analysis.view_data', raise_exception=True)
def view_performance_data(request):
    # Analysts and Admins can view data
    pass
```

### 3.3 Tenant Isolation

**Multi-Tenancy Security**:

```python
# Tenant resolution middleware (django-tenants)
from django_tenants.middleware.main import TenantMainMiddleware

class TenantMainMiddleware:
    def process_request(self, request):
        # Extract hostname
        hostname = request.get_host().split(':')[0]

        # Resolve tenant from domain
        domain = Domain.objects.select_related('tenant').get(domain=hostname)
        tenant = domain.tenant

        # Set PostgreSQL schema
        connection.set_tenant(tenant)
        connection.set_schema(tenant.schema_name)

        # Attach to request
        request.tenant = tenant
```

**Schema Isolation Verification**:
```sql
-- Ensure current_schema matches tenant
SELECT current_schema();  -- Should be 'tenant1', 'tenant2', etc.

-- Prevent cross-schema queries
REVOKE ALL ON SCHEMA public FROM app_user;
GRANT USAGE ON SCHEMA tenant1 TO app_user;  -- Only when tenant1 is active
```

---

## 4. Data Security

### 4.1 Encryption

#### Data in Transit

**TLS Configuration** (Production):
```nginx
# Minimum TLS 1.2
ssl_protocols TLSv1.2 TLSv1.3;

# Strong cipher suites
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:...';
ssl_prefer_server_ciphers on;

# HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

**Django Settings**:
```python
# Force HTTPS
SECURE_SSL_REDIRECT = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# Secure cookies
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
CSRF_COOKIE_HTTPONLY = True

# HSTS
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
```

#### Data at Rest

**Database Encryption**:
- PostgreSQL: Transparent Data Encryption (TDE) via Azure
- Application-level: pgcrypto for sensitive columns (if needed)

**Backup Encryption**:
- Azure Database for PostgreSQL: Encrypted backups (AES-256)
- Geo-redundant storage with encryption

**Secrets Management**:
```python
# Azure Key Vault integration
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

vault_url = os.environ['AZURE_KEY_VAULT_URL']
credential = DefaultAzureCredential()
client = SecretClient(vault_url=vault_url, credential=credential)

# Retrieve secrets
db_password = client.get_secret('database-password').value
secret_key = client.get_secret('django-secret-key').value
```

### 4.2 Data Sanitization

#### Input Validation

**CSV Upload Validation**:
```python
import csv
import re

def validate_csv_upload(csv_file):
    """Validate uploaded CSV for security issues."""
    reader = csv.reader(csv_file)

    for row in reader:
        for cell in row:
            # Reject CSV injection attempts
            if cell.startswith(('=', '+', '-', '@', '\t', '\r')):
                raise ValidationError(f"Invalid cell content: {cell}")

            # Validate data types
            if not is_valid_metric(cell):
                raise ValidationError(f"Invalid metric value: {cell}")

    return True
```

**API Input Validation**:
```python
from rest_framework import serializers

class PerformanceUploadSerializer(serializers.Serializer):
    machine_id = serializers.RegexField(
        regex=r'^[a-zA-Z0-9_-]+$',
        max_length=100,
        error_messages={'invalid': 'Invalid machine_id format'}
    )
    file = serializers.FileField()

    def validate_file(self, value):
        # File size limit: 10MB
        if value.size > 10 * 1024 * 1024:
            raise serializers.ValidationError("File too large")

        # File type validation
        if not value.name.endswith('.csv'):
            raise serializers.ValidationError("Only CSV files allowed")

        return value
```

#### Output Sanitization

**CSV Export**:
```python
def sanitize_csv_cell(value):
    """Sanitize cell content to prevent CSV injection."""
    if isinstance(value, str):
        # Prepend single quote to disable formula execution
        if value.startswith(('=', '+', '-', '@', '\t', '\r')):
            return f"'{value}"
    return value

def export_to_csv(queryset):
    """Export data with sanitization."""
    writer = csv.writer(response)
    for row in queryset:
        sanitized_row = [sanitize_csv_cell(cell) for cell in row]
        writer.writerow(sanitized_row)
```

### 4.3 Data Retention & Deletion

**Retention Policy**:
- Performance data: 90 days (configurable per tenant)
- Audit logs: 1 year
- Backup retention: 7 days

**Automated Cleanup**:
```python
# Django management command
from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta

class Command(BaseCommand):
    help = 'Delete old performance data'

    def handle(self, *args, **options):
        cutoff_date = timezone.now() - timedelta(days=90)
        deleted_count = AnalysisData.objects.filter(
            timestamp__lt=cutoff_date
        ).delete()[0]

        self.stdout.write(
            self.style.SUCCESS(f'Deleted {deleted_count} old records')
        )
```

**Data Deletion (GDPR/CCPA Compliance)**:
- User requests deletion via support ticket
- Tenant Admin confirms deletion request
- 30-day grace period (data marked for deletion)
- Permanent deletion from database and backups

---

## 5. Network Security

### 5.1 Network Architecture

**Production Network Topology**:

```
                   Internet
                      │
                      ▼
        ┌─────────────────────────┐
        │  Azure Front Door       │
        │  (WAF + DDoS)           │
        └─────────────────────────┘
                      │
                      ▼
        ┌─────────────────────────┐
        │  Virtual Network        │
        │  (10.0.0.0/16)          │
        │                         │
        │  ┌──────────────────┐   │
        │  │ Web Subnet       │   │
        │  │ (10.0.1.0/24)    │   │
        │  │                  │   │
        │  │ • App Service    │   │
        │  └──────────────────┘   │
        │                         │
        │  ┌──────────────────┐   │
        │  │ Data Subnet      │   │
        │  │ (10.0.2.0/24)    │   │
        │  │                  │   │
        │  │ • PostgreSQL     │   │
        │  └──────────────────┘   │
        └─────────────────────────┘
```

**Firewall Rules** (Network Security Groups):

```yaml
Web Subnet (10.0.1.0/24):
  Inbound:
    - Priority: 100
      Source: AzureFrontDoor.Backend
      Destination: 10.0.1.0/24
      Port: 443
      Action: Allow

    - Priority: 110
      Source: CollectorIPs (optional whitelist)
      Destination: 10.0.1.0/24
      Port: 8080
      Action: Allow

    - Priority: 200
      Source: Any
      Destination: Any
      Port: Any
      Action: Deny

  Outbound:
    - Priority: 100
      Destination: 10.0.2.0/24
      Port: 5432
      Action: Allow (PostgreSQL)

    - Priority: 200
      Destination: Internet
      Port: 443
      Action: Allow (external APIs)

Data Subnet (10.0.2.0/24):
  Inbound:
    - Priority: 100
      Source: 10.0.1.0/24
      Destination: 10.0.2.0/24
      Port: 5432
      Action: Allow

    - Priority: 200
      Source: Any
      Destination: Any
      Port: Any
      Action: Deny

  Outbound:
    - Priority: 100
      Destination: Internet
      Port: 443
      Action: Allow (backups, updates)
```

### 5.2 Web Application Firewall (WAF)

**Azure Front Door WAF Rules**:

```yaml
OWASP Top 10 Protection:
  - SQL Injection
  - Cross-Site Scripting (XSS)
  - Local File Inclusion (LFI)
  - Remote File Inclusion (RFI)
  - Command Injection

Custom Rules:
  - Rate Limiting: 1000 req/min per IP
  - Geo-blocking: Block high-risk countries (optional)
  - IP Whitelist: Allow only known collector IPs
```

### 5.3 Rate Limiting

**Django Rate Limiting**:

```python
from django_ratelimit.decorators import ratelimit

@ratelimit(key='ip', rate='100/m', method='ALL')
def api_endpoint(request):
    """General API endpoints: 100 requests per minute."""
    pass

@ratelimit(key='header:authorization', rate='10/m', method='POST')
def upload_endpoint(request):
    """Upload endpoint: 10 uploads per minute per API key."""
    pass

@ratelimit(key='user', rate='5/m', method='POST')
def login_endpoint(request):
    """Login endpoint: 5 attempts per minute per user."""
    pass
```

**Nginx Rate Limiting** (Production):

```nginx
# Define rate limit zone
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/m;
limit_req_zone $http_authorization zone=upload_limit:10m rate=10r/m;

# Apply to locations
location /api/ {
    limit_req zone=api_limit burst=20 nodelay;
    proxy_pass http://app_backend;
}

location /api/v1/performance/upload {
    limit_req zone=upload_limit burst=5 nodelay;
    proxy_pass http://app_backend;
}
```

---

## 6. Security Best Practices

### 6.1 OWASP Top 10 Mitigations

| Vulnerability | Mitigation | Implementation |
|---------------|------------|----------------|
| **A01: Broken Access Control** | • RBAC enforcement<br>• Tenant isolation<br>• Permission checks | Django permissions, multi-tenancy middleware |
| **A02: Cryptographic Failures** | • TLS 1.2+<br>• HTTPS-only<br>• Secure cookies | Django SECURE_* settings, Azure TLS |
| **A03: Injection** | • ORM queries<br>• Input validation<br>• Parameterized SQL | Django ORM, serializers |
| **A04: Insecure Design** | • Threat modeling<br>• Security architecture<br>• Defense in depth | This document! |
| **A05: Security Misconfiguration** | • Secure defaults<br>• Hardened settings<br>• Minimal permissions | Django production settings |
| **A06: Vulnerable Components** | • Dependency scanning<br>• Regular updates<br>• Security patches | Dependabot, `pip-audit` |
| **A07: Auth & Session Mgmt** | • Strong passwords<br>• Session timeout<br>• Secure cookies | Django auth, MFA optional |
| **A08: Software & Data Integrity** | • Code signing<br>• Integrity checks<br>• Audit logs | Git signing, checksums |
| **A09: Logging & Monitoring** | • Security logs<br>• Alerting<br>• Incident response | Azure Monitor, custom alerts |
| **A10: Server-Side Request Forgery** | • URL validation<br>• Network isolation<br>• No user-controlled URLs | Input validation, VNet |

### 6.2 Secure Development Lifecycle

**Code Review Checklist**:
- [ ] Input validation on all user inputs
- [ ] Output sanitization for all exports
- [ ] Authentication/authorization checks
- [ ] No hardcoded credentials
- [ ] Error messages don't leak sensitive info
- [ ] SQL queries use ORM (no raw SQL)
- [ ] File uploads validated (type, size)
- [ ] CSRF protection enabled
- [ ] XSS protection (template escaping)

**Security Testing**:
- Static Analysis: `bandit` (Python), `gosec` (Go)
- Dependency Scanning: `pip-audit`, `safety` (Python)
- Automated Testing: Django test suite with security tests
- Manual Penetration Testing: Annual third-party assessment

### 6.3 Secrets Management

**Development Environment**:
```bash
# .env file (NOT committed to git)
SECRET_KEY=dev-secret-key-change-in-production
DATABASE_URL=postgresql://perfadmin:devpassword123@localhost:5432/perfanalysis
DEBUG=True
```

**Production Environment**:
```python
# Azure Key Vault
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Authenticate with Managed Identity
credential = DefaultAzureCredential()
vault_url = os.environ['AZURE_KEY_VAULT_URL']
client = SecretClient(vault_url=vault_url, credential=credential)

# Retrieve secrets
SECRET_KEY = client.get_secret('django-secret-key').value
DATABASE_URL = client.get_secret('database-url').value
```

**Secret Rotation**:
- Database credentials: Rotate every 90 days
- Django SECRET_KEY: Rotate annually
- API keys: Rotate on demand (key compromise)

---

## 7. Incident Response

### 7.1 Incident Classification

| Severity | Definition | Response Time | Examples |
|----------|------------|---------------|----------|
| **Critical** | Data breach, system compromise | <1 hour | Database exposed, admin account hacked |
| **High** | Service disruption, vulnerability | <4 hours | DDoS attack, XSS vulnerability |
| **Medium** | Suspicious activity, minor issue | <24 hours | Failed login attempts, rate limit exceeded |
| **Low** | Informational, no immediate risk | <7 days | Outdated dependency, config warning |

### 7.2 Incident Response Process

**Phase 1: Detection**
- Azure Monitor alerts
- Security log analysis
- User reports

**Phase 2: Containment**
- Isolate affected systems
- Disable compromised credentials
- Block malicious IPs

**Phase 3: Eradication**
- Patch vulnerabilities
- Remove malicious code
- Restore from clean backups

**Phase 4: Recovery**
- Restore services
- Verify system integrity
- Monitor for recurrence

**Phase 5: Post-Incident**
- Root cause analysis
- Update security controls
- Document lessons learned

### 7.3 Communication Plan

**Internal Communication**:
1. Incident detected → Notify security team
2. Severity assessed → Notify management
3. Containment in progress → Status updates every 2 hours
4. Incident resolved → Post-mortem meeting

**External Communication** (if customer data affected):
1. Notify affected tenants within 24 hours
2. Provide incident summary and impact
3. Outline remediation steps
4. Offer support resources

---

## 8. Compliance

### 8.1 Regulatory Requirements

**GDPR** (if EU customers):
- Right to access: API for data export
- Right to erasure: Data deletion process
- Data portability: CSV export format
- Breach notification: 72-hour reporting

**CCPA** (if California residents):
- Data disclosure: Privacy policy
- Opt-out: Do Not Sell My Data
- Data deletion: Request process

**SOC 2** (future certification):
- Security controls documentation
- Audit logging
- Access controls
- Incident response plan

### 8.2 Compliance Controls

**Data Processing Agreement (DPA)**:
- Tenant = Data Controller
- PerfAnalysis = Data Processor
- Subprocessors: Azure (cloud provider)

**Privacy Policy Requirements**:
- Data collection practices
- Data retention policies
- Third-party services
- User rights (access, deletion)

**Audit Requirements**:
- Annual security assessment
- Quarterly access reviews
- Monthly log analysis
- Real-time alerting

---

## 9. Security Checklist

### 9.1 Production Deployment Checklist

**Before Go-Live**:
- [ ] All secrets moved to Azure Key Vault
- [ ] DEBUG=False in production
- [ ] HTTPS enforced (SECURE_SSL_REDIRECT=True)
- [ ] Database backups automated (7-day retention)
- [ ] WAF rules configured
- [ ] Rate limiting enabled
- [ ] Security headers configured
- [ ] Audit logging enabled
- [ ] Monitoring alerts configured
- [ ] Incident response plan documented
- [ ] Security assessment completed
- [ ] Penetration test conducted

**Ongoing Maintenance**:
- [ ] Weekly: Review security logs
- [ ] Monthly: Update dependencies
- [ ] Quarterly: Rotate credentials
- [ ] Annually: Security assessment

---

## 10. Security Contacts

**Security Team**:
- Security Architect: [Contact Info]
- DevOps Engineer: [Contact Info]
- Solutions Architect: [Contact Info]

**Incident Reporting**:
- Email: security@perfanalysis.example.com
- On-Call: [Phone Number]
- Slack: #security-incidents

**Vulnerability Disclosure**:
- Responsible disclosure: security@perfanalysis.example.com
- Bug bounty: [Program Details]

---

**Document Status**: ✅ Complete
**Next Review**: 2026-02-05
**Owner**: Security Architect
**Classification**: Internal
