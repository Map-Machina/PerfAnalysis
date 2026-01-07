# PerfAnalysis Agent Directory

**Version**: 1.2
**Last Updated**: 2026-01-06
**Total Agents**: 19
**Project**: PerfAnalysis - Integrated Performance Monitoring Ecosystem

---

## Quick Reference

This directory provides a quick index of all available agents for the PerfAnalysis project. For detailed usage instructions, routing rules, and collaboration patterns, see [`AGENT_MANIFEST.yaml`](AGENT_MANIFEST.yaml).

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    PERFANALYSIS ECOSYSTEM                        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ perfcollector2  │────────▶│   XATbackend    │────────▶│   automated-    │
│   (Go-based)    │         │ (Django Portal) │         │   Reporting     │
│                 │         │  + Dashboard    │         │   (R-based)     │
│ DATA COLLECTION │         │ USER PORTAL     │         │ PDF REPORTS     │
└─────────────────┘         └─────────────────┘         └─────────────────┘
                                    │
                                    ▼
                            ┌─────────────────┐
                            │   Interactive   │
                            │   Dashboard     │
                            │  (Plotly.js)    │
                            │ VISUALIZATION   │
                            └─────────────────┘
```

**Data Flow**: Linux /proc → perfcollector2 → XATbackend → Dashboard/automated-Reporting

---

## Agent Categories

### 🔧 Backend Development (3 agents)

| # | Agent | Component | Key Expertise | File |
|---|-------|-----------|---------------|------|
| 1 | **Go Backend Developer** | perfcollector2 | Go programming, /proc parsing, HTTP APIs, data collection | [`backend/go-backend-developer.md`](backend/go-backend-developer.md) |
| 2 | **Backend Python Developer** | XATbackend | Django 3.2.3, REST APIs, ORM optimization, multi-tenant apps | [`backend/backend-python-developer.md`](backend/backend-python-developer.md) |
| 3 | **Django Tenants Specialist** | XATbackend | django-tenants 3.3.1, schema isolation, tenant security | [`backend/django-tenants-specialist.md`](backend/django-tenants-specialist.md) |

### 🎨 Frontend Development (1 agent)

| # | Agent | Component | Key Expertise | File |
|---|-------|-----------|---------------|------|
| 4 | **Frontend Developer** | XATbackend Dashboard | JavaScript, Plotly.js, DataTables, WebSockets, responsive design | [`frontend/frontend-developer.md`](frontend/frontend-developer.md) |

### 🔄 Operational & Automation (4 agents)

| # | Agent | Component | Key Expertise | File |
|---|-------|-----------|---------------|------|
| 5 | **Linux Systems Engineer** | perfcollector2 | /proc filesystem, device discovery, sysstat, metric collection | [`operational/linux-systems-engineer.md`](operational/linux-systems-engineer.md) |
| 6 | **Automation Engineer** | All | CLI design, workflow orchestration, job scheduling, batch processing | [`operational/automation-engineer.md`](operational/automation-engineer.md) |
| 7 | **Configuration Management Specialist** | All | YAML/JSON configs, secrets management, environment variables | [`operational/configuration-management-specialist.md`](operational/configuration-management-specialist.md) |
| 8 | **Data Quality Engineer** | All | Data validation, quality metrics, error detection, input validation | [`operational/data-quality-engineer.md`](operational/data-quality-engineer.md) |

### 🚀 Performance (1 agent)

| # | Agent | Component | Key Expertise | File |
|---|-------|-----------|---------------|------|
| 9 | **R Performance Expert** | automated-Reporting | R optimization, vectorization, data.table, R Markdown, ggplot2 | [`performance/r-performance-expert.md`](performance/r-performance-expert.md) |

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
| 16 | **Solutions Architect** | All | System architecture, Azure deployment, scalability, HA/DR, multi-region | [`architecture/solutions-architect-sais.md`](architecture/solutions-architect-sais.md) |
| 17 | **DevOps Engineer** | XATbackend | Docker, Azure App Service, GitHub Actions, CI/CD, monitoring | [`architecture/devops-engineer.md`](architecture/devops-engineer.md) |
| 18 | **OCI Architect Professional** | All | OCI compute, storage, networking, database, security, multicloud/hybrid, migration | [`architecture/oci-architect-professional.md`](architecture/oci-architect-professional.md) |
| 19 | **OCI DevOps Professional** | All | OCI DevOps service, Terraform, OKE, CI/CD pipelines, containerization, DevSecOps | [`architecture/oci-devops-professional.md`](architecture/oci-devops-professional.md) |

---

## Agent-Component Matrix

### perfcollector2 Agents

**Primary Responsibility**: Collect performance metrics from Linux /proc filesystem

| Agent | Role |
|-------|------|
| Go Backend Developer | Core implementation (pcc, pcd, pcprocess) |
| Linux Systems Engineer | /proc parsing, device discovery |
| Configuration Management Specialist | Config files, environment variables |
| Data Quality Engineer | Metric validation |
| Integration Architect | Upload to XATbackend |

### XATbackend Agents

**Primary Responsibility**: Multi-tenant user portal for data storage, management, and interactive dashboards

| Agent | Role |
|-------|------|
| Backend Python Developer | Django application development, REST APIs |
| Django Tenants Specialist | Multi-tenancy implementation |
| **Frontend Developer** | Interactive dashboards with Plotly.js |
| Security Architect | Authentication, authorization |
| DevOps Engineer | Azure deployment, CI/CD |
| Data Architect | Database schema design |
| Integration Architect | API endpoints for upload/export |

### automated-Reporting Agents

**Primary Responsibility**: Visualization and performance analysis

| Agent | Role |
|-------|------|
| R Performance Expert | Report generation, chart optimization |
| Data Architect | Data transformation |
| Time-Series Architect | Time-series analysis |
| Oracle Developer | Database integration (future) |

### Cross-Cutting Agents

**Primary Responsibility**: System-wide concerns

| Agent | Scope |
|-------|-------|
| Integration Architect | End-to-end data flow orchestration |
| API Architect | REST API design across all components |
| Security Architect | Security across all systems |
| Solutions Architect | Overall system architecture |
| Automation Engineer | Automation workflows |
| Configuration Management Specialist | Configuration across all components |

---

## Quick Consultation Guide

### By Technology

| Technology | Consult Agent |
|------------|---------------|
| **Go** | Go Backend Developer |
| **Python/Django** | Backend Python Developer |
| **django-tenants** | Django Tenants Specialist |
| **JavaScript/Plotly.js** | Frontend Developer |
| **DataTables.js** | Frontend Developer |
| **WebSockets** | Frontend Developer, Backend Python Developer |
| **R/R Markdown** | R Performance Expert |
| **PostgreSQL** | Data Architect, Django Tenants Specialist |
| **Oracle** | Oracle Developer, Data Architect |
| **Linux /proc** | Linux Systems Engineer |
| **Azure** | DevOps Engineer, Solutions Architect |
| **OCI (Oracle Cloud)** | OCI Architect Professional, OCI DevOps Professional |
| **Terraform/IaC** | OCI DevOps Professional, DevOps Engineer |
| **Kubernetes/OKE** | OCI DevOps Professional |
| **Docker** | DevOps Engineer, OCI DevOps Professional |
| **REST API** | API Architect, Integration Architect |

### By Task Type

| Task | Primary Agent | Supporting Agents |
|------|---------------|-------------------|
| **Add new metric to perfcollector2** | Linux Systems Engineer | Go Backend Developer, Data Quality Engineer |
| **Implement upload endpoint** | Integration Architect | Backend Python Developer, Security Architect |
| **Build interactive dashboard** | Frontend Developer | Backend Python Developer, API Architect |
| **Create dashboard REST API** | Backend Python Developer | API Architect, Frontend Developer |
| **Optimize R report** | R Performance Expert | Data Architect |
| **Design database schema** | Data Architect | Time-Series Architect, Django Tenants Specialist |
| **Set up authentication** | Security Architect | Backend Python Developer, Go Backend Developer |
| **Deploy to production** | DevOps Engineer | Solutions Architect, Security Architect |
| **Troubleshoot data flow** | Integration Architect | All component-specific agents |
| **Configure automation** | Automation Engineer | Configuration Management Specialist |
| **Validate data quality** | Data Quality Engineer | Component-specific agents |
| **Design OCI architecture** | OCI Architect Professional | Solutions Architect, Security Architect |
| **Set up OCI CI/CD pipeline** | OCI DevOps Professional | OCI Architect Professional |
| **Deploy to OKE (Kubernetes)** | OCI DevOps Professional | OCI Architect Professional |
| **Migrate workloads to OCI** | OCI Architect Professional | OCI DevOps Professional, Data Architect |

### By Problem Domain

| Problem | Consult Agent |
|---------|---------------|
| **Slow data collection** | Go Backend Developer, Linux Systems Engineer |
| **Upload failures** | Integration Architect, Backend Python Developer |
| **Cross-tenant data leak** | Django Tenants Specialist, Security Architect |
| **Slow R reports** | R Performance Expert, Data Architect |
| **Dashboard not loading** | Frontend Developer, Backend Python Developer |
| **Chart rendering issues** | Frontend Developer |
| **Database performance** | Data Architect, Time-Series Architect |
| **API design** | API Architect, Integration Architect |
| **Security vulnerability** | Security Architect |
| **Deployment issues** | DevOps Engineer, Solutions Architect |
| **Configuration errors** | Configuration Management Specialist |
| **Data validation errors** | Data Quality Engineer |

---

## Usage Examples

### Example 1: Basic Consultation

```
User: "As the Go Backend Developer, help me add /proc/loadavg parsing to pcc."
```

### Example 2: Multi-Agent Collaboration

```
User: "Integration Architect and Security Architect: Design the authenticated
      upload API between perfcollector2 and XATbackend."
```

### Example 3: Keyword-Based (Auto-Routed)

```
User: "How do I implement tenant isolation for performance data?"
→ Auto-routed to: Django Tenants Specialist
```

### Example 4: Complex Integration

```
User: "Integration Architect: Walk me through the complete data flow from
      /proc filesystem collection to R report generation."
```

---

## Common Integration Workflows

### Workflow 1: End-to-End Setup

1. **Linux Systems Engineer** - Identify metrics to collect
2. **Go Backend Developer** - Implement pcc collection
3. **Configuration Management Specialist** - Set up config files
4. **Security Architect** - Generate API keys
5. **Backend Python Developer** - Create upload endpoint
6. **Django Tenants Specialist** - Configure multi-tenancy
7. **Integration Architect** - Test data flow
8. **R Performance Expert** - Set up reporting
9. **DevOps Engineer** - Deploy to production

### Workflow 2: Add New Machine

1. **Linux Systems Engineer** - Install pcc on server
2. **Configuration Management Specialist** - Configure collection parameters
3. **Security Architect** - Generate machine API key
4. **Backend Python Developer** - Register machine in portal
5. **Integration Architect** - Verify upload working

### Workflow 3: Generate Report

1. **Backend Python Developer** - Export data from portal
2. **Data Quality Engineer** - Validate data
3. **R Performance Expert** - Generate report
4. **Integration Architect** - Publish to portal

---

## Agent Expertise Heat Map

### perfcollector2 Component

```
█████ Go Backend Developer
████  Linux Systems Engineer
███   Configuration Management Specialist
███   Data Quality Engineer
███   Integration Architect
██    Security Architect
█     API Architect
```

### XATbackend Component

```
█████ Backend Python Developer
█████ Django Tenants Specialist
████  Security Architect
████  DevOps Engineer
███   Data Architect
███   Integration Architect
██    API Architect
██    Solutions Architect
```

### automated-Reporting Component

```
█████ R Performance Expert
████  Data Architect
███   Time-Series Architect
██    Oracle Developer
██    Integration Architect
```

### Integration Layer

```
█████ Integration Architect
████  API Architect
████  Security Architect
███   Solutions Architect
```

---

## Data Flow by Agent

### Stage 1: Collection (Linux → perfcollector2)

**Agents Involved**:
- Linux Systems Engineer (metric identification)
- Go Backend Developer (pcc implementation)
- Configuration Management Specialist (config setup)
- Data Quality Engineer (validation)

**Output**: JSON/CSV files with raw metrics

---

### Stage 2: Upload (perfcollector2 → XATbackend)

**Agents Involved**:
- Integration Architect (workflow design)
- Go Backend Developer (upload client)
- Backend Python Developer (upload endpoint)
- Security Architect (authentication)
- Django Tenants Specialist (tenant association)

**Output**: Data stored in PostgreSQL with multi-tenant isolation

---

### Stage 3: Storage (XATbackend Database)

**Agents Involved**:
- Django Tenants Specialist (schema isolation)
- Data Architect (schema design)
- Time-Series Architect (partitioning strategy)
- Security Architect (access control)

**Output**: Queryable performance database

---

### Stage 4: Export (XATbackend → automated-Reporting)

**Agents Involved**:
- Backend Python Developer (export API/command)
- Integration Architect (format specification)
- Data Quality Engineer (export validation)

**Output**: CSV files for R consumption

---

### Stage 5: Visualization (automated-Reporting)

**Agents Involved**:
- R Performance Expert (report generation)
- Data Architect (data transformation)
- Time-Series Architect (time-series analysis)

**Output**: HTML/PDF performance reports

---

## Technology Stack Reference

| Component | Languages | Frameworks | Database | Cloud |
|-----------|-----------|------------|----------|-------|
| **perfcollector2** | Go 1.21+ | net/http, encoding/json | N/A | N/A |
| **XATbackend** | Python 3.x | Django 3.2.3, django-tenants 3.3.1 | PostgreSQL 12.2 | Azure App Service |
| **automated-Reporting** | R 4.5.2 | R Markdown, ggplot2, data.table | Oracle 26ai (future) | N/A |

---

## Critical Integration Points

### 1. perfcollector2 → XATbackend

**Endpoint**: `POST /api/v1/performance/upload`
**Format**: Multipart form data (CSV file)
**Authentication**: Bearer token (API key)
**Primary Agents**: Integration Architect, Go Backend Developer, Backend Python Developer

### 2. XATbackend → automated-Reporting

**Method**: CSV file export or REST API (future)
**Format**: CSV with standardized column names
**Primary Agents**: Backend Python Developer, R Performance Expert, Integration Architect

### 3. perfcollector2 → automated-Reporting (Direct)

**Method**: Direct CSV file access (for testing/development)
**Format**: CSV output from pcprocess
**Primary Agents**: Go Backend Developer, R Performance Expert

---

## Getting Started

### For New Developers

1. **Read the System Overview** - Understand the 3-component architecture
2. **Review the Agent Manifest** - See [`AGENT_MANIFEST.yaml`](AGENT_MANIFEST.yaml) for detailed routing rules
3. **Identify Your Component** - Determine which component you're working on
4. **Consult Relevant Agents** - Use the "Quick Consultation Guide" above

### For Specific Tasks

1. **Identify the Task Type** - Use the "By Task Type" table
2. **Find Primary Agent** - This is your starting point
3. **Check Supporting Agents** - These provide additional context
4. **Consult Using Examples** - See "Usage Examples" section

### For Integration Work

1. **Start with Integration Architect** - Overall data flow design
2. **Consult Component Agents** - For implementation details
3. **Review Security with Security Architect** - Ensure secure integration
4. **Test with Data Quality Engineer** - Validate data integrity

---

## File Structure

```
agents/
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
│   ├── data-architect.md           # Schema design
│   └── time-series-architect.md    # Time-series DB
├── integration/
│   └── integration-architect.md    # System integration
├── operational/
│   ├── automation-engineer.md      # Automation & CLI
│   ├── configuration-management-specialist.md # Config management
│   ├── data-quality-engineer.md    # Data validation
│   └── linux-systems-engineer.md   # Linux /proc metrics
└── performance/
    └── r-performance-expert.md     # R optimization
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-04 | Initial directory created with 16 agents |
| 1.1 | 2026-01-05 | Added Frontend Developer agent |
| 1.2 | 2026-01-06 | Added OCI Architect Professional and OCI DevOps Professional agents |

---

## Support & Feedback

For questions about agent usage or to suggest improvements:
- Review the detailed manifest: [`AGENT_MANIFEST.yaml`](AGENT_MANIFEST.yaml)
- Consult the Integration Architect for system-wide questions
- Consult component-specific agents for implementation details

---

## Legend

- 🔧 **Backend Development** - Application code implementation
- 🔄 **Operational** - System operations and automation
- 🚀 **Performance** - Optimization and tuning
- 💾 **Database** - Data storage and architecture
- 🏗️ **Architecture** - System design and infrastructure
- 🔗 **Integration** - Cross-system data flow

---

**Quick Links**:
- [Agent Manifest (YAML)](AGENT_MANIFEST.yaml) - Detailed routing and collaboration rules
- [Integration Architect](integration/integration-architect.md) - Start here for system-wide questions
- [Go Backend Developer](backend/go-backend-developer.md) - perfcollector2 development
- [Backend Python Developer](backend/backend-python-developer.md) - XATbackend development
- [R Performance Expert](performance/r-performance-expert.md) - automated-Reporting development

---

**Pro Tip**: When in doubt, consult the **Integration Architect** first. They can guide you to the right specialized agent for your specific task.
