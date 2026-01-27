# PerfAnalysis

**Integrated Performance Monitoring Ecosystem for Linux Servers**

[![Production Ready](https://img.shields.io/badge/status-production%20ready-brightgreen)]()
[![Tests](https://img.shields.io/badge/tests-92.3%25%20passing-brightgreen)]()
[![Documentation](https://img.shields.io/badge/docs-complete-blue)]()

---

## Overview

PerfAnalysis is a complete, production-ready performance monitoring system that collects, stores, analyzes, and visualizes system metrics from Linux servers.

### Key Features

- 📊 **Real-time Performance Monitoring**: Collect CPU, memory, disk, and network metrics
- 🔐 **Multi-Tenant Architecture**: Complete data isolation for multiple organizations
- 🌐 **Web-Based Portal**: User-friendly interface for managing collectors and data
- 📈 **Interactive Dashboards**: React-based visualization with real-time updates
- 🔒 **Enterprise Security**: API authentication, RBAC, TLS encryption
- 🐳 **Container-Native**: Docker-based deployment for all components

---

## Quick Start

### Prerequisites

- Docker Desktop or Docker + Docker Compose
- 4GB RAM minimum (8GB recommended)
- 10GB disk space

### Installation

```bash
# Clone repository
git clone https://github.com/Map-Machina/PerfAnalysis.git
cd PerfAnalysis

# Start all services
make init

# Verify health
make health
```

**Access the portal**: http://localhost:8000

---

## System Architecture

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ perfcollector2  │────────▶│  XATSimplified  │────────▶│  perf-dashboard │
│   (Go-based)    │  HTTP   │ (Django 4.2 API)│  REST   │   (React 18)    │
│                 │  POST   │                 │   API   │                 │
│ DATA COLLECTION │         │ BACKEND API     │         │ VISUALIZATION   │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

> **Note**: XATbackend is deprecated. All production development uses **XATSimplified**.

### Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| **perfcollector2** | Go 1.24 | Collects metrics from Linux `/proc` filesystem |
| **XATSimplified** | Django 4.2.9 | REST API, multi-tenant data management |
| **perf-dashboard** | React 18 | Interactive dashboards and visualization |
| **PostgreSQL** | 12.2+ | Multi-tenant data storage |

---

## Features

### Data Collection (perfcollector2)

- ✅ CPU utilization (per core)
- ✅ Memory usage and swap
- ✅ Disk I/O statistics
- ✅ Network interface metrics
- ✅ Filesystem usage
- ✅ Process information

### Web Portal (XATbackend)

- ✅ Collector registration and management
- ✅ File upload and storage
- ✅ User authentication and RBAC
- ✅ RESTful API with authentication
- ✅ Multi-tenant data isolation
- ✅ Performance data analysis

### Reporting (automated-Reporting)

- ✅ CPU usage trends
- ✅ Memory consumption analysis
- ✅ Network traffic visualization
- ✅ Disk I/O patterns
- ✅ Custom report templates

---

## Documentation

### User Documentation

- **[User Guide](USER_GUIDE.md)** (58KB) - Complete user manual with API reference
- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** (62KB) - Production deployment options
- **[Performance Optimization](PERFORMANCE_OPTIMIZATION.md)** (65KB) - Optimization strategies

### Technical Documentation

- **[Architecture](ARCHITECTURE.md)** (95KB) - System architecture and design
- **[Security](SECURITY.md)** (48KB) - Security architecture and threat model
- **[CI/CD](CI_CD.md)** (43KB) - Continuous integration and deployment

### Project Status

- **[Phase 1 Summary](PHASE1_SUMMARY.md)** - Environment setup and CI/CD
- **[Phase 2 Summary](PHASE2_SUMMARY.md)** - Core development documentation
- **[Phase 3 Summary](PHASE3_SUMMARY.md)** - Testing and optimization
- **[Project Status](PROJECT_STATUS.md)** - Overall project status
- **[E2E Test Results](E2E_TEST_RESULTS.md)** - End-to-end load test results

---

## Testing

### Test Coverage

- **Integration Tests**: 12/12 passing (100%)
- **Unit Tests**: 72-85% code coverage
- **Load Tests**: Validated up to 100 concurrent users
- **E2E Tests**: 92.3% success rate

### Running Tests

```bash
# Integration tests
cd tests/integration
pytest test_e2e_data_flow.py -v

# Performance benchmarks
cd perfcollector2
go test -bench=. -benchmem ./...

# Load testing
cd tests/performance
python load_test.py --scenario medium

# End-to-end test
python3 scripts/simple_e2e_test.py
```

### Generate Test Data

```bash
# Generate synthetic performance data
python3 scripts/generate_test_data.py --scenario heavy --duration 60
```

---

## Deployment Options

### 1. Docker Compose (Recommended for Small-Medium Scale)

**Best for**: 50-100 collectors, single server

```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 2. Kubernetes (Large Scale)

**Best for**: 100+ collectors, high availability

```bash
kubectl apply -f k8s/
```

### 3. AWS Cloud-Native

**Best for**: Enterprise deployments

```bash
terraform apply
```

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for details.

---

## Performance

| Metric | Target | Actual |
|--------|--------|--------|
| Collection Latency | <100ms | 85ms ✅ |
| API Response (p95) | <500ms | 420ms ✅ |
| Database Query (p95) | <100ms | 85ms ✅ |
| System Throughput | >1,000/s | 1,250/s ✅ |

---

## Security

- ✅ TLS 1.2+ encryption
- ✅ API key authentication (PBKDF2-SHA256)
- ✅ Role-Based Access Control (Admin/Analyst/Viewer)
- ✅ Multi-tenant data isolation (PostgreSQL schemas)
- ✅ OWASP Top 10 mitigations
- ✅ Security headers (HSTS, CSP, X-Frame-Options)

See [SECURITY.md](SECURITY.md) for details.

---

## Contributing

We welcome contributions! Please see our contributing guidelines.

### Development Setup

```bash
# Clone repository
git clone https://github.com/Map-Machina/PerfAnalysis.git
cd PerfAnalysis

# Initialize development environment
make init

# Run tests
make test
```

### Restarting Services After Updates

**Important**: After making changes to the XATbackend code (models, views, templates), you must restart the Docker services for the changes to take effect:

```bash
# Restart all services
docker compose down && docker compose up -d

# Or restart just the web backend
docker compose restart xatbackend

# Verify services are running
docker compose ps
```

This applies to:
- Model changes (collectors/models.py)
- View changes (dashboard/views.py)
- Template changes (dashboard/templates/)
- Settings changes (core/settings.py)

### Code Quality

- Go: golangci-lint with 20 linters
- Python: black + flake8 + pylint
- R: lintr

---

## License

MIT License - see LICENSE file for details.

---

## Support

- **Documentation**: See all .md files in repository
- **Issues**: https://github.com/Map-Machina/PerfAnalysis/issues
- **Email**: support@perfanalysis.com

---

## Project Status

✅ **Production Ready**

- All 3 development phases complete
- 92.3% end-to-end test success rate
- Comprehensive documentation (12,000+ lines)
- Multiple deployment options
- Security hardened
- Performance validated

See [PROJECT_STATUS.md](PROJECT_STATUS.md) for detailed status.

---

## Quick Links

- **Getting Started**: [USER_GUIDE.md](USER_GUIDE.md)
- **Deployment**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **API Documentation**: [USER_GUIDE.md#api-reference](USER_GUIDE.md#api-reference)
- **Performance Tuning**: [PERFORMANCE_OPTIMIZATION.md](PERFORMANCE_OPTIMIZATION.md)
- **Architecture Details**: [ARCHITECTURE.md](ARCHITECTURE.md)

---

**Built with ❤️ using Go, Django, R, and Docker**
