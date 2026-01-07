# OCI - Oracle Cloud Infrastructure Performance Analysis

This directory contains artifacts related to Oracle Cloud Infrastructure for performance analysis of OCI-based resources.

## Purpose

- Performance collection and analysis for OCI compute instances
- Infrastructure as Code (Terraform) templates for OCI deployments
- OCI DevOps pipeline configurations
- Monitoring and observability configurations
- Benchmark automation for OCI resources

## Directory Structure

```
OCI/
├── README.md                     # This file
├── docs/                         # Documentation
│   └── PROJECT_PLAN_PERFTEST_COMPARTMENT.md  # Deployment plan
├── agents/                       # 19 specialized Claude agents
│   ├── 00-AGENT_DIRECTORY.md     # Quick reference
│   ├── AGENT_MANIFEST.yaml       # Detailed manifest
│   └── [agent categories]/       # Agent definitions
├── terraform/                    # Infrastructure as Code
│   ├── modules/                  # Reusable Terraform modules
│   │   ├── compartment/          # Compartment hierarchy
│   │   ├── vcn/                  # VCN and networking
│   │   ├── compute/              # VM instances
│   │   └── security/             # Security resources
│   └── environments/             # Environment configurations
│       └── perftest/             # Performance testing environment
├── devops/                       # OCI DevOps service configs
│   ├── build_specs/              # Build pipeline specifications
│   └── deployment_specs/         # Deployment pipeline specifications
├── monitoring/                   # Monitoring and observability
│   ├── alarms/                   # OCI Alarm definitions
│   └── dashboards/               # Custom dashboard configurations
├── scripts/                      # Utility scripts
└── benchmarks/                   # Benchmark configurations
    ├── configs/                  # Benchmark configuration files
    └── results/                  # Benchmark result storage
```

## Quick Start: Deploy PerfTest Environment

### Prerequisites

1. **OCI Account**: Sign up for [OCI Free Tier](https://www.oracle.com/cloud/free/)
2. **OCI CLI**: Install and configure `~/.oci/config`
3. **Terraform**: Install Terraform 1.5+
4. **SSH Key**: Generate with `ssh-keygen -t ed25519`

### Deployment Steps

```bash
# Navigate to perftest environment
cd terraform/environments/perftest

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your OCI credentials

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply

# View connection information
terraform output ssh_connection_info
```

### Cost: $0/month (Free Tier)

| Resource | Specification | Free Tier Limit |
|----------|---------------|-----------------|
| Compute | 2x VM.Standard.A1.Flex (1 OCPU, 6GB) | 3,000 OCPU-hours/month |
| Storage | 2x 50GB Boot Volume | 200 GB total |
| Network | NAT Gateway, VCN | Included |

## Related Agents

For OCI-related tasks, consult these specialized agents in `agents/`:

| Agent | Certification | Use For |
|-------|---------------|---------|
| **OCI Architect Professional** | 1Z0-997-25 | Infrastructure design, VCN, security, HA/DR |
| **OCI DevOps Professional** | 1Z0-1109-25 | Terraform, OKE, CI/CD pipelines |

### Agent Usage Examples

```
"As the OCI Architect Professional, design a multi-AD architecture for
high availability deployment of PerfAnalysis."

"As the OCI DevOps Professional, create a build_spec.yaml for building
the XATbackend container image."
```

## Terraform Modules

### compartment/
Creates hierarchical compartment structure:
- PerfAnalysis (parent)
  - PerfTest-Network
  - PerfTest-Compute
  - PerfTest-Security

### vcn/
Creates networking infrastructure:
- VCN with configurable CIDR
- Public subnet (bastion access)
- Private subnet (compute instances)
- Internet Gateway, NAT Gateway, Service Gateway
- Route tables and security lists

### compute/
Creates Always Free tier compute instances:
- Supports ARM (A1.Flex) and AMD (E2.1.Micro) shapes
- Cloud-init installs Go, sysbench, pcc
- Configurable instance count

## Integration with PerfAnalysis

### Data Flow
```
OCI Compute (pcc) → JSON → CSV → XATbackend Portal → Reports
```

### Components
- **perfcollector2**: Deploy `pcc` binary on OCI compute instances
- **XATbackend**: Upload performance data via REST API
- **automated-Reporting**: Generate visualizations from collected data

## Key OCI Services Used

| Service | Purpose | Free Tier |
|---------|---------|-----------|
| **Compute** | Performance test VMs | ✅ A1.Flex or E2.1.Micro |
| **VCN** | Network isolation | ✅ Included |
| **NAT Gateway** | Outbound connectivity | ✅ Included |
| **Object Storage** | Data storage (future) | ✅ 10 GB |
| **Monitoring** | Metrics and alarms | ✅ Basic tier |

## Documentation

- [Project Plan: PerfTest Compartment](docs/PROJECT_PLAN_PERFTEST_COMPARTMENT.md)
- [OCI Free Tier Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)

## References

- [OCI Documentation](https://docs.oracle.com/en-us/iaas/Content/home.htm)
- [OCI Best Practices](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/bestpractices.htm)
- [OCI DevOps Documentation](https://docs.oracle.com/en-us/iaas/Content/devops/using/home.htm)
- [OCI Architect Professional Certification](https://education.oracle.com/oracle-cloud-infrastructure-2025-certified-architect-professional/trackp_OCICAP2025OPN)
- [OCI DevOps Professional Certification](https://education.oracle.com/oracle-cloud-infrastructure-2025-certified-devops-professional/trackp_OCI25DOPOCP)
