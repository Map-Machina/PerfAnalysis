# CI/CD Pipeline Documentation

**Version**: 1.0
**Date**: 2026-01-05
**Agent Assignment**: DevOps Engineer
**Status**: Active

---

## Table of Contents

1. [Overview](#overview)
2. [GitHub Actions Workflows](#github-actions-workflows)
3. [Code Quality Gates](#code-quality-gates)
4. [Testing Strategy](#testing-strategy)
5. [Deployment Pipeline](#deployment-pipeline)
6. [Monitoring & Alerts](#monitoring--alerts)
7. [Troubleshooting](#troubleshooting)

---

## 1. Overview

The PerfAnalysis CI/CD pipeline automates code quality checks, testing, security scanning, and deployment across all three components of the system.

### 1.1 Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      CI/CD PIPELINE                               │
└──────────────────────────────────────────────────────────────────┘

Code Push/PR
     │
     ├─────────────┬─────────────┬─────────────┐
     ▼             ▼             ▼             ▼
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  Lint   │  │  Test   │  │Security │  │  Build  │
│         │  │         │  │  Scan   │  │         │
└────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘
     │            │            │            │
     └────────────┴────────────┴────────────┘
                  │
                  ▼
         ┌────────────────┐
         │  Integration   │
         │     Tests      │
         └────────┬───────┘
                  │
     ┌────────────┴────────────┐
     ▼                         ▼
┌─────────┐              ┌─────────┐
│ Staging │              │  Main   │
│ Deploy  │              │ Deploy  │
│(develop)│              │ (main)  │
└─────────┘              └─────────┘
```

### 1.2 Workflow Triggers

| Workflow | Trigger | Components |
|----------|---------|------------|
| **Component CI** | Push/PR to main/develop | Individual component changes |
| **Integration Tests** | Push to main/develop, Daily | All components |
| **Security Scan** | Push to main, Weekly | All components |
| **Deploy Staging** | Push to develop | XATbackend only |
| **Deploy Production** | Push to main (manual approval) | XATbackend only |

---

## 2. GitHub Actions Workflows

### 2.1 perfcollector2 CI/CD

**File**: `.github/workflows/perfcollector2-ci.yml`

**Jobs**:

1. **Lint** (Go Code Quality)
   - `go vet` - Static analysis
   - `go fmt` - Code formatting check
   - `golangci-lint` - Comprehensive linting
   - **Pass Criteria**: No errors, code properly formatted

2. **Test** (Unit Tests)
   - `go test -race` - Run tests with race detector
   - Coverage report generation
   - Upload to Codecov
   - **Pass Criteria**: All tests pass, coverage >70%

3. **Build** (Cross-platform)
   - Build for: linux/amd64, linux/arm64, darwin/amd64, darwin/arm64
   - Upload artifacts (binaries)
   - **Pass Criteria**: Clean build for all platforms

4. **Security** (Vulnerability Scanning)
   - `govulncheck` - Go vulnerability database
   - `gosec` - Security audit
   - SARIF report upload
   - **Pass Criteria**: No critical/high vulnerabilities

5. **Docker** (Container Build)
   - Build Docker image
   - Test image execution
   - Cache layers for faster builds
   - **Pass Criteria**: Image builds and runs successfully

**Execution Time**: ~5-8 minutes

### 2.2 XATbackend CI/CD

**File**: `.github/workflows/xatbackend-ci.yml`

**Jobs**:

1. **Lint** (Python Code Quality)
   - `black` - Code formatter check
   - `flake8` - Style guide enforcement
   - `pylint` - Static analysis (min score: 7.0)
   - **Pass Criteria**: No formatting issues, pylint score ≥7.0

2. **Security** (Dependency & Code Scanning)
   - `bandit` - Python security linter
   - `safety` - Dependency vulnerability check
   - `pip-audit` - PyPI vulnerability scan
   - **Pass Criteria**: No critical vulnerabilities

3. **Test** (Django Tests)
   - PostgreSQL service container
   - Run migrations
   - Execute test suite with coverage
   - **Pass Criteria**: All tests pass, coverage >80%

4. **Docker** (Container Build)
   - Build Docker image
   - Test Django check command
   - **Pass Criteria**: Image builds successfully

5. **Deploy Staging** (develop branch only)
   - Deploy to Azure App Service (staging)
   - **Pass Criteria**: Deployment successful, health check passes

**Execution Time**: ~8-12 minutes

### 2.3 automated-Reporting CI/CD

**File**: `.github/workflows/automated-reporting-ci.yml`

**Jobs**:

1. **Lint** (R Code Quality)
   - `lintr` - R code linting
   - Style guide checks
   - **Pass Criteria**: No linting errors

2. **Test** (R Script Execution)
   - Initialize renv environment
   - Render R Markdown report
   - Upload HTML artifact
   - **Pass Criteria**: Report renders successfully

3. **Docker** (Container Build)
   - Build R development image
   - Test R version
   - **Pass Criteria**: Image builds successfully

**Execution Time**: ~10-15 minutes (R package installation)

### 2.4 Integration Tests

**File**: `.github/workflows/integration-tests.yml`

**Jobs**:

1. **Full Stack Integration**
   - Build all services with Docker Compose
   - Start PostgreSQL, XATbackend, pcd, r-dev
   - Run migrations
   - Execute health checks
   - Test data flow (placeholder for actual tests)
   - **Pass Criteria**: All services start, health checks pass

2. **Dependency Review** (PRs only)
   - Review dependency changes
   - Check for vulnerabilities
   - **Pass Criteria**: No moderate+ severity vulnerabilities

3. **CodeQL Analysis** (Python & Go)
   - Static security analysis
   - SARIF report upload
   - **Pass Criteria**: No critical findings

**Execution Time**: ~15-20 minutes

---

## 3. Code Quality Gates

### 3.1 Go (perfcollector2)

**Configuration**: `.golangci.yml`

**Enabled Linters** (20 linters):
- `errcheck` - Unchecked errors
- `gosimple` - Code simplification
- `govet` - Go vet analysis
- `staticcheck` - Static analysis
- `gosec` - Security issues
- `gocyclo` - Cyclomatic complexity (max: 15)
- `goconst` - Repeated strings
- And 13 more...

**Quality Thresholds**:
- Max cyclomatic complexity: 15
- Min test coverage: 70%
- Zero unchecked errors
- All code gofmt-ed

**Running Locally**:
```bash
cd perfcollector2

# Run linter
golangci-lint run

# Run tests with coverage
go test -v -race -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Run security scan
gosec ./...
```

### 3.2 Python (XATbackend)

**Configuration**: `.pylintrc`, `.flake8`

**Code Quality Tools**:
- **black** - Opinionated code formatter (120 char line length)
- **flake8** - PEP 8 style guide enforcement
- **pylint** - Static analysis (min score: 7.0/10)
- **bandit** - Security linter
- **safety** - Dependency vulnerability scanner

**Quality Thresholds**:
- Pylint score: ≥7.0
- Max line length: 120 characters
- Max complexity: 10
- Min test coverage: 80%

**Running Locally**:
```bash
cd XATbackend

# Format code
black .

# Run linters
flake8 .
pylint --rcfile=.pylintrc */

# Run security checks
bandit -r .
safety check

# Run tests with coverage
coverage run --source='.' manage.py test
coverage report
```

### 3.3 R (automated-Reporting)

**Code Quality Tools**:
- **lintr** - R code linter
- **renv** - Package management
- R Markdown rendering test

**Quality Thresholds**:
- No lintr errors
- Report renders successfully
- Max line length: 120 characters

**Running Locally**:
```bash
cd automated-Reporting

# Run linter
R -e "lintr::lint_dir('.')"

# Test report rendering
R -e "rmarkdown::render('reporting.Rmd')"
```

---

## 4. Testing Strategy

### 4.1 Test Pyramid

```
           ┌──────────────┐
           │  End-to-End  │  ← Integration Tests (Daily)
           │    Tests     │
           └──────────────┘
        ┌──────────────────┐
        │  Integration     │  ← Component Integration (On Push)
        │     Tests        │
        └──────────────────┘
    ┌────────────────────────┐
    │      Unit Tests        │  ← Component Tests (On Push)
    │                        │
    └────────────────────────┘
```

### 4.2 Unit Tests

**perfcollector2** (Go):
```bash
# Run all tests
go test ./...

# Run with race detector
go test -race ./...

# Run with coverage
go test -coverprofile=coverage.out ./...
```

**Test Structure**:
```
perfcollector2/
├── measurement/
│   └── measurement_test.go
├── collector/
│   └── collector_test.go
└── api/
    └── api_test.go
```

**XATbackend** (Django):
```bash
# Run all tests
python manage.py test

# Run specific app tests
python manage.py test collectors

# Run with coverage
coverage run --source='.' manage.py test
coverage report
```

**Test Structure**:
```
XATbackend/
├── collectors/
│   └── tests/
│       ├── test_models.py
│       ├── test_views.py
│       └── test_api.py
├── analysis/
│   └── tests/
└── partners/
    └── tests/
```

### 4.3 Integration Tests

**Full Stack Test** (Docker Compose):
```bash
# Start all services
docker-compose up -d

# Run migrations
docker-compose exec xatbackend python manage.py migrate

# Run integration tests
docker-compose exec xatbackend python manage.py test --tag=integration

# Tear down
docker-compose down -v
```

**Test Scenarios**:
1. PostgreSQL connectivity
2. Django migrations
3. pcd daemon startup
4. R environment initialization
5. Cross-service communication (future)

### 4.4 End-to-End Tests

**Planned** (not yet implemented):
1. Data collection → Upload → Storage → Export → Report
2. Multi-tenant isolation verification
3. API authentication flow
4. Report generation pipeline

---

## 5. Deployment Pipeline

### 5.1 Deployment Environments

| Environment | Branch | Trigger | Approval Required |
|-------------|--------|---------|-------------------|
| **Development** | Local | Manual | No |
| **Staging** | develop | Automatic | No |
| **Production** | main | Manual | Yes |

### 5.2 Staging Deployment (develop branch)

**Workflow**: `.github/workflows/xatbackend-ci.yml` → `deploy-staging` job

**Steps**:
1. All CI checks pass (lint, test, security)
2. Docker image built successfully
3. Deploy to Azure App Service (staging slot)
4. Run smoke tests
5. Notify team via Slack/Email

**Environment**:
- URL: https://staging.perfanalysis.example.com
- Database: Staging PostgreSQL (isolated)
- API Keys: Test/staging keys only

**Rollback**:
- Automatic rollback if health check fails
- Manual rollback via Azure Portal

### 5.3 Production Deployment (main branch)

**Workflow**: Manual trigger (GitHub Actions dispatch)

**Steps**:
1. All CI checks pass
2. Integration tests pass
3. Security scans clean
4. Manual approval required
5. Deploy to production slot
6. Smoke tests
7. Swap slots (blue-green deployment)

**Environment**:
- URL: https://perfanalysis.example.com
- Database: Production PostgreSQL (encrypted)
- API Keys: Production keys (rotated)

**Pre-deployment Checklist**:
- [ ] All tests passing
- [ ] Security scans clean
- [ ] Database migrations tested in staging
- [ ] Rollback plan documented
- [ ] On-call engineer available

**Rollback Plan**:
1. Swap slots back to previous version (instant)
2. Restore database from backup (if needed)
3. Notify users of downtime

---

## 6. Monitoring & Alerts

### 6.1 CI/CD Metrics

**GitHub Actions**:
- Workflow success rate
- Average build time per component
- Test coverage trends
- Security vulnerability trends

**Dashboards**:
- GitHub Actions dashboard (built-in)
- Codecov (code coverage)
- Security alerts (GitHub Security tab)

### 6.2 Deployment Metrics

**Azure Monitor** (Production):
- Deployment frequency
- Deployment success rate
- Mean time to recovery (MTTR)
- Change failure rate

**Alerts**:
- CI/CD pipeline failures → Slack/Email
- Security vulnerabilities detected → Email + GitHub issue
- Deployment failures → PagerDuty + Slack
- Test coverage drops below threshold → Slack

### 6.3 Alert Configuration

**GitHub Actions Notifications**:
```yaml
# .github/workflows/notify.yml (example)
- name: Notify on failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'CI pipeline failed!'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

**Azure Monitor Alerts**:
- HTTP 5xx errors > 10/minute
- Response time p95 > 2 seconds
- Database connection pool > 80%
- Disk usage > 85%

---

## 7. Troubleshooting

### 7.1 Common CI/CD Issues

#### Issue: Go build fails with "go.mod requires go >= 1.24.2"

**Cause**: GitHub Actions using older Go version

**Solution**:
```yaml
- name: Set up Go
  uses: actions/setup-go@v5
  with:
    go-version: '1.24'  # Update to match go.mod
```

#### Issue: Python tests fail with "ModuleNotFoundError"

**Cause**: Missing dependencies or incorrect PYTHONPATH

**Solution**:
```yaml
- name: Install dependencies
  run: |
    pip install -r requirements.txt
    pip install pytest pytest-django
```

#### Issue: Docker build fails with "no such file or directory"

**Cause**: Build context doesn't include required files

**Solution**:
```yaml
- name: Build Docker image
  uses: docker/build-push-action@v5
  with:
    context: ./perfcollector2  # Ensure correct context
    file: ./perfcollector2/Dockerfile.dev
```

#### Issue: Integration tests timeout

**Cause**: Services not starting in time

**Solution**:
```bash
# Increase timeout
timeout 120 bash -c 'until docker-compose exec -T postgres pg_isready; do sleep 2; done'

# Check logs
docker-compose logs postgres
```

### 7.2 Debugging Failed Workflows

**View Logs**:
1. Go to GitHub Actions tab
2. Click on failed workflow run
3. Click on failed job
4. Expand failed step

**Download Artifacts**:
```bash
# Using gh CLI
gh run download <run-id>

# Manual download from Actions UI
# Artifacts tab → Download
```

**Re-run Failed Jobs**:
```bash
# Using gh CLI
gh run rerun <run-id>

# Or click "Re-run failed jobs" in Actions UI
```

### 7.3 Performance Optimization

**Caching**:
- Go modules: `~/.cache/go-build`
- Python packages: `~/.cache/pip`
- R packages: `$R_LIBS_USER`
- Docker layers: `type=gha` (GitHub Actions cache)

**Parallel Execution**:
- Matrix builds for cross-platform (Go)
- Parallel test execution (pytest -n auto)
- Concurrent Docker builds

**Workflow Optimization Tips**:
1. Use `actions/cache` for dependencies
2. Only run workflows on relevant path changes
3. Use `continue-on-error` for non-critical jobs
4. Set appropriate timeouts
5. Use Docker layer caching

---

## 8. CI/CD Best Practices

### 8.1 Code Review Process

**Required Checks** (for PR merge):
- [ ] All CI workflows pass
- [ ] Code review approved (1+ reviewer)
- [ ] Test coverage maintained/improved
- [ ] No security vulnerabilities
- [ ] Documentation updated

**Branch Protection Rules**:
- Require status checks before merging
- Require code review approval
- Require linear history
- No force push to main/develop

### 8.2 Security Best Practices

1. **Secrets Management**:
   - Use GitHub Secrets for sensitive data
   - Rotate secrets regularly
   - Never commit secrets to code

2. **Dependency Management**:
   - Automated dependency updates (Dependabot)
   - Regular security audits
   - Pin major versions, allow patch updates

3. **Container Security**:
   - Scan images for vulnerabilities
   - Use minimal base images (Alpine)
   - Run as non-root user

### 8.3 Documentation

**Required Documentation**:
- [ ] README.md - Setup and usage
- [ ] CI_CD.md - This document
- [ ] ARCHITECTURE.md - System design
- [ ] SECURITY.md - Security guidelines

**Changelog**:
- Keep CHANGELOG.md updated
- Follow semantic versioning
- Document breaking changes

---

## 9. Quick Reference

### 9.1 Common Commands

**Run CI locally** (approximation):
```bash
# perfcollector2
cd perfcollector2
golangci-lint run
go test -race ./...
make build

# XATbackend
cd XATbackend
black --check .
pylint */
python manage.py test

# Full stack
docker-compose up -d
docker-compose exec xatbackend python manage.py test
docker-compose down -v
```

### 9.2 Workflow Files

| Component | Workflow File | Purpose |
|-----------|---------------|---------|
| perfcollector2 | `.github/workflows/perfcollector2-ci.yml` | Go CI/CD |
| XATbackend | `.github/workflows/xatbackend-ci.yml` | Django CI/CD |
| automated-Reporting | `.github/workflows/automated-reporting-ci.yml` | R CI/CD |
| Integration | `.github/workflows/integration-tests.yml` | Full stack tests |

### 9.3 Configuration Files

| File | Purpose | Component |
|------|---------|-----------|
| `.golangci.yml` | Go linter config | perfcollector2 |
| `.pylintrc` | Python linter config | XATbackend |
| `.flake8` | Python style config | XATbackend |
| `docker-compose.yml` | Local dev environment | All |

---

## 10. Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-01-05 | Initial CI/CD pipeline documentation | DevOps Engineer |

---

**Document Status**: ✅ Complete
**Next Review**: 2026-02-05
**Owner**: DevOps Engineer
**Tags**: CI/CD, GitHub Actions, Testing, Deployment
