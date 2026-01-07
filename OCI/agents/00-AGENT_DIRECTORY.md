# OCI Performance Analysis Agent Directory

**Version**: 1.0
**Last Updated**: 2026-01-06
**Total Agents**: 19
**Project**: PerfAnalysis OCI - Oracle Cloud Infrastructure Performance Analysis

---

## Quick Reference

This directory provides a quick index of all available agents for OCI-based performance analysis within the PerfAnalysis ecosystem. For detailed usage instructions, routing rules, and collaboration patterns, see [`AGENT_MANIFEST.yaml`](AGENT_MANIFEST.yaml).

---

## Agent Categories

### 🔧 Backend Development (3 agents)

| # | Agent | Component | Key Expertise | File |
|---|-------|-----------|---------------|------|
| 1 | **Go Backend Developer** | perfcollector2 | Go programming, /proc parsing, HTTP client/server, JSON/CSV | [`backend/go-backend-developer.md`](backend/go-backend-developer.md) |
| 2 | **Backend Python Developer** | XATbackend | Django 3.2.3, REST APIs, PostgreSQL, async processing | [`backend/backend-python-developer.md`](backend/backend-python-developer.md) |
| 3 | **Django Tenants Specialist** | XATbackend | django-tenants, multi-tenancy, schema isolation, domain routing | [`backend/django-tenants-specialist.md`](backend/django-tenants-specialist.md) |

### 🖥️ Frontend Development (1 agent)

| # | Agent | Component | Key Expertise | File |
|---|-------|-----------|---------------|------|
| 4 | **Frontend Developer** | XATbackend | JavaScript, Plotly.js, DataTables, Django templates | [`frontend/frontend-developer.md`](frontend/frontend-developer.md) |

### ⚙️ Operational & Automation (4 agents)

| # | Agent | Component | Key Expertise | File |
|---|-------|-----------|---------------|------|
| 5 | **Linux Systems Engineer** | perfcollector2 | /proc filesystem, system metrics, device discovery, sysstat | [`operational/linux-systems-engineer.md`](operational/linux-systems-engineer.md) |
| 6 | **Automation Engineer** | All | CLI design, workflow orchestration, job scheduling, pipelines | [`operational/automation-engineer.md`](operational/automation-engineer.md) |
| 7 | **Configuration Management Specialist** | All | YAML/JSON config, environment variables, secrets management | [`operational/configuration-management-specialist.md`](operational/configuration-management-specialist.md) |
| 8 | **Data Quality Engineer** | All | Data validation, quality metrics, input sanitization, anomaly detection | [`operational/data-quality-engineer.md`](operational/data-quality-engineer.md) |

### 📊 Performance (1 agent)

| # | Agent | Component | Key Expertise | File |
|---|-------|-----------|---------------|------|
| 9 | **R Performance Expert** | automated-Reporting | R optimization, data.table, ggplot2, R Markdown, profiling | [`performance/r-performance-expert.md`](performance/r-performance-expert.md) |

### 💾 Database & Data Architecture (3 agents)

| # | Agent | Component | Key Expertise | File |
|---|-------|-----------|---------------|------|
| 10 | **Data Architect** | All | Schema design, time-series modeling, partitioning, query optimization | [`database/data-architect.md`](database/data-architect.md) |
| 11 | **Time-Series Architect** | All | Metric aggregation, retention policies, monitoring systems, partitioning | [`database/time-series-architect.md`](database/time-series-architect.md) |
| 12 | **Oracle Developer** | automated-Reporting | PL/SQL, Oracle 26ai, stored procedures, vector search (future) | [`database/agent-oracle-developer.md`](database/agent-oracle-developer.md) |

### 🏗️ Architecture & Infrastructure (7 agents)

| # | Agent | Component | Key Expertise | File |
|---|-------|-----------|---------------|------|
| 13 | **Integration Architect** | All | Multi-system integration, data pipelines, API contracts, end-to-end flow | [`integration/integration-architect.md`](integration/integration-architect.md) |
| 14 | **API Architect** | All | REST API design, versioning, endpoint structure, integration patterns | [`architecture/api-architect.md`](architecture/api-architect.md) |
| 15 | **Security Architect** | All | OWASP Top 10, authentication, API keys, multi-tenant security, encryption | [`architecture/security-architect.md`](architecture/security-architect.md) |
| 16 | **Solutions Architect** | All | System architecture, cloud deployment, scalability, HA/DR, multi-region | [`architecture/solutions-architect-sais.md`](architecture/solutions-architect-sais.md) |
| 17 | **DevOps Engineer** | XATbackend | Docker, Azure App Service, GitHub Actions, CI/CD, monitoring | [`architecture/devops-engineer.md`](architecture/devops-engineer.md) |
| 18 | **OCI Architect Professional** | All | OCI compute, storage, networking, database, security, multicloud/hybrid, migration | [`architecture/oci-architect-professional.md`](architecture/oci-architect-professional.md) |
| 19 | **OCI DevOps Professional** | All | OCI DevOps service, Terraform, OKE, CI/CD pipelines, containerization, DevSecOps | [`architecture/oci-devops-professional.md`](architecture/oci-devops-professional.md) |

---

## OCI-Specific Agent Selection

### Primary OCI Agents

| Agent | Certification | Use For |
|-------|---------------|---------|
| **OCI Architect Professional** | 1Z0-997-25 | Infrastructure design, VCN, compute, storage, security, HA/DR, migration |
| **OCI DevOps Professional** | 1Z0-1109-25 | Terraform, OKE, CI/CD pipelines, build specs, deployment strategies |

### OCI Task Routing

| Task | Primary Agent | Supporting Agents |
|------|---------------|-------------------|
| **Design OCI architecture** | OCI Architect Professional | Solutions Architect, Security Architect |
| **Create VCN and networking** | OCI Architect Professional | Security Architect |
| **Set up OCI DevOps pipeline** | OCI DevOps Professional | OCI Architect Professional |
| **Deploy to OKE (Kubernetes)** | OCI DevOps Professional | OCI Architect Professional |
| **Write Terraform modules** | OCI DevOps Professional | Automation Engineer |
| **Configure Resource Manager** | OCI DevOps Professional | OCI Architect Professional |
| **Implement IAM policies** | OCI Architect Professional | Security Architect |
| **Plan workload migration** | OCI Architect Professional | OCI DevOps Professional, Data Architect |
| **Set up OCI monitoring** | OCI Architect Professional | DevOps Engineer |
| **Configure OCI Vault** | Security Architect | OCI Architect Professional |

---

## Agent Selection by Technology

| Technology | Primary Agent(s) |
|------------|------------------|
| **OCI Compute** | OCI Architect Professional |
| **OCI Networking (VCN)** | OCI Architect Professional |
| **OCI Storage** | OCI Architect Professional |
| **OKE (Kubernetes)** | OCI DevOps Professional |
| **OCI DevOps Service** | OCI DevOps Professional |
| **Terraform** | OCI DevOps Professional |
| **Resource Manager** | OCI DevOps Professional |
| **Helm Charts** | OCI DevOps Professional |
| **Ansible OCI Collection** | OCI DevOps Professional |
| **OCI IAM** | OCI Architect Professional, Security Architect |
| **OCI Vault** | Security Architect, OCI Architect Professional |
| **Autonomous Database** | Oracle Developer, Data Architect |
| **Go (perfcollector2)** | Go Backend Developer |
| **Python/Django** | Backend Python Developer |
| **R/R Markdown** | R Performance Expert |
| **PostgreSQL** | Data Architect |
| **Docker** | DevOps Engineer, OCI DevOps Professional |

---

## Usage Examples

### OCI Architecture Design

```
"As the OCI Architect Professional, design a highly available architecture
for deploying PerfAnalysis on OCI with multi-AD distribution and DR."
```

### OCI DevOps Pipeline

```
"As the OCI DevOps Professional, create a build_spec.yaml for building
and deploying the XATbackend container to OKE."
```

### Multi-Agent Collaboration

```
"OCI Architect Professional and OCI DevOps Professional: Design the
infrastructure and CI/CD pipeline for deploying perfcollector2 across
multiple OCI compute instances."
```

### Migration Planning

```
"As the OCI Architect Professional, plan the migration of our Azure-hosted
XATbackend to OCI, including database migration and network configuration."
```

---

## File Structure

```
OCI/agents/
├── 00-AGENT_DIRECTORY.md           # This file - Quick reference
├── AGENT_MANIFEST.yaml             # Detailed manifest with routing rules
├── architecture/
│   ├── api-architect.md            # REST API design
│   ├── devops-engineer.md          # Deployment & CI/CD
│   ├── oci-architect-professional.md # OCI 2025 Architect Professional
│   ├── oci-devops-professional.md  # OCI 2025 DevOps Professional
│   ├── security-architect.md       # Security & authentication
│   └── solutions-architect-sais.md # System architecture
├── backend/
│   ├── backend-python-developer.md # Django development
│   ├── django-tenants-specialist.md # Multi-tenancy
│   └── go-backend-developer.md     # Go development
├── database/
│   ├── agent-oracle-developer.md   # Oracle/PL-SQL
│   ├── data-architect.md           # Database design
│   └── time-series-architect.md    # Time-series data
├── frontend/
│   └── frontend-developer.md       # JavaScript/UI development
├── integration/
│   └── integration-architect.md    # System integration
├── operational/
│   ├── automation-engineer.md      # Automation & CLI
│   ├── configuration-management-specialist.md
│   ├── data-quality-engineer.md    # Data validation
│   └── linux-systems-engineer.md   # Linux /proc expertise
└── performance/
    └── r-performance-expert.md     # R optimization
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-06 | Initial OCI agent directory with 19 agents from PerfAnalysis |

---

## Quick Links

- [Agent Manifest (YAML)](AGENT_MANIFEST.yaml) - Detailed routing and collaboration rules
- [OCI Architect Professional](architecture/oci-architect-professional.md) - OCI infrastructure design
- [OCI DevOps Professional](architecture/oci-devops-professional.md) - OCI DevOps and IaC
- [Integration Architect](integration/integration-architect.md) - System-wide questions

---

**Pro Tip**: For OCI-specific tasks, start with **OCI Architect Professional** for infrastructure design or **OCI DevOps Professional** for automation and deployment.
