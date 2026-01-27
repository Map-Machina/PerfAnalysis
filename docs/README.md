# PerfAnalysis Documentation

This directory contains organized documentation for the PerfAnalysis ecosystem.

## Directory Structure

```
docs/
├── README.md                    # This file
├── architecture/                # System architecture documentation
│   ├── SYSTEM_OVERVIEW.md      # High-level system design (planned)
│   ├── DATA_FLOW.md            # Data flow between components (planned)
│   └── COMPONENT_DIAGRAM.md    # Component relationships (planned)
├── deployment/                  # Deployment guides
│   ├── DOCKER.md               # Docker Compose deployment (planned)
│   ├── AZURE.md                # Azure deployment (planned)
│   └── KUBERNETES.md           # Kubernetes deployment (planned)
├── api/                         # API documentation
│   ├── AUTHENTICATION.md       # Auth endpoints and flows (planned)
│   ├── COLLECTORS.md           # Collector management API (planned)
│   └── BENCHMARKS.md           # Benchmark API (planned)
├── guides/                      # User and developer guides
│   ├── ENVIRONMENT_SETUP.md    # Environment variables reference ✅
│   ├── QUICK_START.md          # Getting started (planned)
│   ├── DEVELOPER_SETUP.md      # Development environment (planned)
│   └── TROUBLESHOOTING.md      # Common issues and solutions (planned)
└── legacy/                      # Archived documentation
    └── XATBACKEND_REFERENCE.md # XATbackend reference (planned)
```

## Available Documentation

### Guides
- **[Environment Setup](guides/ENVIRONMENT_SETUP.md)** - Complete reference for environment variables across all components

## Planned Documentation

The following documentation is planned for future phases:

### Architecture (Phase 2)
- System Overview - High-level system design
- Data Flow - How data moves between components
- Component Diagram - Visual component relationships

### Deployment (Phase 2-3)
- Docker Deployment - Local Docker Compose setup
- Azure Deployment - Production Azure deployment
- Kubernetes Deployment - Scalable K8s deployment

### API Reference (Phase 2)
- Authentication API - JWT tokens, registration, password management
- Collectors API - Collector registration and management
- Benchmarks API - Performance benchmark endpoints

### Developer Guides (Phase 2)
- Quick Start - Getting started in 5 minutes
- Developer Setup - Full development environment
- Troubleshooting - Common issues and solutions

## Component Documentation

Each component has its own `CLAUDE.md` file with detailed guidance:

| Component | Documentation | Status |
|-----------|---------------|--------|
| **XATSimplified** | [XATSimplified/CLAUDE.md](../XATSimplified/CLAUDE.md) | ✅ Production |
| **perf-dashboard** | [perf-dashboard/CLAUDE.md](../perf-dashboard/CLAUDE.md) | ✅ Active |
| **perfcollector2** | [perfcollector2/README.md](../perfcollector2/README.md) | ✅ Active |

## Root-Level Documentation

Important files in the repository root:

| File | Description |
|------|-------------|
| [README.md](../README.md) | Project overview and quick start |
| [ARCHITECTURE.md](../ARCHITECTURE.md) | Detailed architecture documentation |
| [SECURITY.md](../SECURITY.md) | Security architecture and guidelines |
| [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) | Comprehensive deployment options |
| [CLEANUP_RECOMMENDATIONS.md](../CLEANUP_RECOMMENDATIONS.md) | Codebase improvement plan |

## Agent Documentation

Specialized Claude AI agents are documented in `/agents/`:

| File | Description |
|------|-------------|
| [agents/README.md](../agents/README.md) | Agent overview and usage guide |
| [agents/00-AGENT_DIRECTORY.md](../agents/00-AGENT_DIRECTORY.md) | Quick reference index |

> **Note**: The `/agents/` directory is the **canonical source** for agent definitions. Other agent directories (XATbackend/agents, automated-Reporting/agents, etc.) are deprecated.

## Note on XATbackend

> ⚠️ **XATbackend is deprecated**. All production development uses **XATSimplified**.
>
> XATbackend code may be used for reference patterns only. See the deprecation notices in:
> - [XATbackend/README.md](../XATbackend/README.md)
> - [legacy/XATBACKEND_REFERENCE.md](legacy/XATBACKEND_REFERENCE.md) (planned)

---

*Last Updated: 2026-01-27*
