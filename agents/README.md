# PerfAnalysis Agents

This directory contains specialized Claude AI agents for the **PerfAnalysis** integrated performance monitoring ecosystem.

## Quick Start

**New here?** Start with:
1. **[Agent Directory](00-AGENT_DIRECTORY.md)** - Quick reference guide to all 16 agents
2. **[Agent Manifest](AGENT_MANIFEST.yaml)** - Detailed manifest with routing rules and collaboration patterns

## What are Agents?

Agents are specialized AI personas with deep expertise in specific domains. Each agent provides:
- Domain-specific knowledge and best practices
- Code examples and implementation guidance
- Troubleshooting and optimization advice
- Integration patterns and workflows

## System Architecture

The PerfAnalysis ecosystem integrates three components:

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ perfcollector2  │────────▶│   XATbackend    │────────▶│   automated-    │
│   (Go-based)    │         │ (Django Portal) │         │   Reporting     │
│                 │         │                 │         │   (R-based)     │
│ DATA COLLECTION │         │ USER PORTAL     │         │ VISUALIZATION   │
└─────────────────┘         └─────────────────┘         └─────────────────┘
```

**Data Flow**: Linux /proc → perfcollector2 → XATbackend → automated-Reporting

## Agent Categories

### 🔧 Backend Development (3 agents)
- **[Go Backend Developer](backend/go-backend-developer.md)** - perfcollector2 (Go-based data collection)
- **[Backend Python Developer](backend/backend-python-developer.md)** - XATbackend (Django portal)
- **[Django Tenants Specialist](backend/django-tenants-specialist.md)** - Multi-tenancy implementation

### 🔄 Operational (4 agents)
- **[Linux Systems Engineer](operational/linux-systems-engineer.md)** - /proc filesystem and metrics
- **[Automation Engineer](operational/automation-engineer.md)** - CLI design and workflow automation
- **[Configuration Management Specialist](operational/configuration-management-specialist.md)** - Config and secrets
- **[Data Quality Engineer](operational/data-quality-engineer.md)** - Data validation

### 🚀 Performance (1 agent)
- **[R Performance Expert](performance/r-performance-expert.md)** - R optimization and visualization

### 💾 Database (3 agents)
- **[Data Architect](database/data-architect.md)** - Schema design and optimization
- **[Time-Series Architect](database/time-series-architect.md)** - Time-series database design
- **[Oracle Developer](database/agent-oracle-developer.md)** - PL/SQL and Oracle integration

### 🏗️ Architecture (5 agents)
- **[Integration Architect](integration/integration-architect.md)** - Multi-system integration (START HERE!)
- **[API Architect](architecture/api-architect.md)** - REST API design
- **[Security Architect](architecture/security-architect.md)** - Authentication and security
- **[Solutions Architect](architecture/solutions-architect-sais.md)** - System architecture
- **[DevOps Engineer](architecture/devops-engineer.md)** - Deployment and CI/CD

## How to Use Agents

### Method 1: Direct Consultation

Address an agent by their role:

```
"As the [Agent Name], help me [specific task]."
```

**Examples**:
```
"As the Go Backend Developer, help me add /proc/loadavg parsing to pcc."

"As the Django Tenants Specialist, fix this cross-tenant data leak."

"As the R Performance Expert, optimize this slow data.frame operation."
```

### Method 2: Multi-Agent Collaboration

For complex tasks requiring multiple perspectives:

```
"[Agent 1] and [Agent 2]: [collaborative task]."
```

**Example**:
```
"Integration Architect and Security Architect: Design the authenticated
 upload API between perfcollector2 and XATbackend."
```

### Method 3: Keyword-Based (Auto-Routing)

Simply mention keywords, and the system will route to the appropriate agent:

| Keyword | Routes To |
|---------|-----------|
| `go`, `golang` | Go Backend Developer |
| `django`, `python` | Backend Python Developer |
| `tenant`, `multi-tenant` | Django Tenants Specialist |
| `r`, `rmarkdown` | R Performance Expert |
| `/proc`, `linux metrics` | Linux Systems Engineer |
| `integration`, `upload` | Integration Architect |
| `security`, `authentication` | Security Architect |
| `database`, `schema` | Data Architect |

## Common Tasks

### Task: Add New Metric to perfcollector2

**Consult**: Linux Systems Engineer → Go Backend Developer → Data Quality Engineer

**Example**:
```
"Linux Systems Engineer: What metrics are available in /proc/vmstat?"
"Go Backend Developer: Implement parsing for /proc/vmstat in pcc."
"Data Quality Engineer: Add validation for vmstat metrics."
```

### Task: Implement Upload Workflow

**Consult**: Integration Architect → Go Backend Developer → Backend Python Developer → Security Architect

**Example**:
```
"Integration Architect: Design the CSV upload workflow from perfcollector2 to XATbackend."
```

### Task: Optimize R Report

**Consult**: R Performance Expert → Data Architect

**Example**:
```
"R Performance Expert: This data.frame operation is taking 30 seconds to process
 100K rows. How can I optimize it?"
```

### Task: Set Up Multi-Tenant Database

**Consult**: Django Tenants Specialist → Data Architect → Time-Series Architect

**Example**:
```
"Django Tenants Specialist and Data Architect: Design the schema for storing
 performance data with proper tenant isolation."
```

### Task: Deploy to Production

**Consult**: DevOps Engineer → Solutions Architect → Security Architect

**Example**:
```
"DevOps Engineer: Deploy XATbackend to Azure App Service with proper security
 and monitoring."
```

## Integration Workflows

### Complete Setup (End-to-End)

1. **Linux Systems Engineer** - Identify metrics to collect
2. **Go Backend Developer** - Implement perfcollector2
3. **Configuration Management Specialist** - Set up configuration
4. **Security Architect** - Generate API keys
5. **Backend Python Developer** - Create upload endpoint
6. **Django Tenants Specialist** - Configure multi-tenancy
7. **Integration Architect** - Test data flow
8. **R Performance Expert** - Set up reporting
9. **DevOps Engineer** - Deploy to production

### Add New Machine

1. **Linux Systems Engineer** - Install pcc on server
2. **Configuration Management Specialist** - Configure collection
3. **Security Architect** - Generate machine API key
4. **Backend Python Developer** - Register machine in portal
5. **Integration Architect** - Verify upload

### Generate Report

1. **Backend Python Developer** - Export data from portal
2. **Data Quality Engineer** - Validate data
3. **R Performance Expert** - Generate report
4. **Integration Architect** - Publish to portal

## Critical Integration Points

### 1. perfcollector2 → XATbackend

**What**: Upload collected performance data
**How**: HTTP POST with CSV file
**Endpoint**: `/api/v1/performance/upload`
**Auth**: Bearer token (API key)
**Agents**: Integration Architect, Go Backend Developer, Backend Python Developer, Security Architect

### 2. XATbackend → automated-Reporting

**What**: Export data for visualization
**How**: CSV file export or REST API
**Format**: Standardized CSV columns
**Agents**: Backend Python Developer, R Performance Expert, Integration Architect

### 3. perfcollector2 → automated-Reporting (Direct)

**What**: Bypass portal for development/testing
**How**: Direct CSV file access
**Agents**: Go Backend Developer, R Performance Expert

## Technology Stack

| Component | Language | Framework | Database | Cloud |
|-----------|----------|-----------|----------|-------|
| **perfcollector2** | Go 1.21+ | net/http, encoding/json | N/A | N/A |
| **XATbackend** | Python 3.x | Django 3.2.3, django-tenants 3.3.1 | PostgreSQL 12.2 | Azure |
| **automated-Reporting** | R 4.5.2 | R Markdown, ggplot2, data.table | Oracle 26ai (future) | N/A |

## File Structure

```
agents/
├── README.md                       # This file - Overview and quick start
├── 00-AGENT_DIRECTORY.md           # Quick reference index
├── AGENT_MANIFEST.yaml             # Detailed manifest with routing rules
├── architecture/                   # System architecture agents
│   ├── api-architect.md
│   ├── devops-engineer.md
│   ├── security-architect.md
│   └── solutions-architect-sais.md
├── backend/                        # Backend development agents
│   ├── backend-python-developer.md
│   ├── django-tenants-specialist.md
│   └── go-backend-developer.md
├── database/                       # Database and data architecture agents
│   ├── agent-oracle-developer.md
│   ├── data-architect.md
│   └── time-series-architect.md
├── integration/                    # Integration and orchestration agents
│   └── integration-architect.md
├── operational/                    # Operational and automation agents
│   ├── automation-engineer.md
│   ├── configuration-management-specialist.md
│   ├── data-quality-engineer.md
│   └── linux-systems-engineer.md
└── performance/                    # Performance optimization agents
    └── r-performance-expert.md
```

## Getting Help

### I'm new to the project
→ Start with **[Integration Architect](integration/integration-architect.md)** for system overview

### I'm working on perfcollector2 (Go)
→ Consult **[Go Backend Developer](backend/go-backend-developer.md)** and **[Linux Systems Engineer](operational/linux-systems-engineer.md)**

### I'm working on XATbackend (Django)
→ Consult **[Backend Python Developer](backend/backend-python-developer.md)** and **[Django Tenants Specialist](backend/django-tenants-specialist.md)**

### I'm working on automated-Reporting (R)
→ Consult **[R Performance Expert](performance/r-performance-expert.md)**

### I'm working on integration between components
→ Consult **[Integration Architect](integration/integration-architect.md)**

### I have a security question
→ Consult **[Security Architect](architecture/security-architect.md)**

### I'm deploying to production
→ Consult **[DevOps Engineer](architecture/devops-engineer.md)**

### I'm designing a database schema
→ Consult **[Data Architect](database/data-architect.md)** and **[Time-Series Architect](database/time-series-architect.md)**

### I'm designing an API
→ Consult **[API Architect](architecture/api-architect.md)**

## Best Practices

### ✅ Do: Be Specific

```
❌ "Help with the database"
✅ "As the Data Architect, design the PostgreSQL schema for storing CPU,
   memory, disk, and network metrics with proper time-series partitioning."
```

### ✅ Do: Provide Context

```
❌ "Optimize this code"
✅ "As the R Performance Expert, this data.frame operation processes 100K rows
   and takes 30 seconds. The input is CPU metrics with timestamp, machine_id,
   and 10 numeric columns. How can I optimize it using data.table?"
```

### ✅ Do: Request Specific Deliverables

```
❌ "Think about security"
✅ "As the Security Architect, create the API key generation and validation
   code for the perfcollector2 upload endpoint with proper token hashing."
```

### ✅ Do: Leverage Multiple Agents

```
✅ "Integration Architect: Design the upload workflow."
✅ "Go Backend Developer: Implement the upload client."
✅ "Backend Python Developer: Implement the upload endpoint."
✅ "Security Architect: Add authentication to the endpoint."
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-04 | Initial agent collection created with 16 specialized agents |

## License

MIT License - See individual project repositories for details.

## Contributing

To update agents or add new ones:
1. Create agent file in appropriate category folder
2. Update [`AGENT_MANIFEST.yaml`](AGENT_MANIFEST.yaml) with agent metadata
3. Update [`00-AGENT_DIRECTORY.md`](00-AGENT_DIRECTORY.md) with quick reference
4. Update this README if needed

---

**Quick Links**:
- 📖 [Agent Directory](00-AGENT_DIRECTORY.md) - Quick reference
- 📋 [Agent Manifest](AGENT_MANIFEST.yaml) - Detailed manifest
- 🔗 [Integration Architect](integration/integration-architect.md) - Start here for integration questions
- 🔧 [Go Backend Developer](backend/go-backend-developer.md) - perfcollector2 development
- 🐍 [Backend Python Developer](backend/backend-python-developer.md) - XATbackend development
- 📊 [R Performance Expert](performance/r-performance-expert.md) - automated-Reporting development

---

**Pro Tip**: When in doubt, start with the **Integration Architect**. They have a system-wide view and can guide you to the right specialist for your task. 🚀
