# OCI Performance Testing Compartment - Project Plan

**Version**: 1.0
**Date**: 2026-01-06
**Author**: OCI Architect Professional Agent
**Status**: Planning

---

## Executive Summary

This project plan outlines the deployment of an OCI compartment for running performance tests using perfcollector2 (pcc) to generate datasets for the XATbackend portal. The design follows Oracle's Well-Architected Framework and utilizes **FREE TIER resources only** for the initial deployment.

---

## 1. Requirements Analysis

### 1.1 Workload Characteristics

| Requirement | Specification |
|-------------|---------------|
| **Purpose** | Run performance benchmarks (sysbench, pcc collection) |
| **Data Flow** | VM → pcc collection → CSV → XATbackend portal upload |
| **CPU** | Light to moderate (benchmark workloads) |
| **Memory** | 1-4 GB per instance |
| **Storage** | Minimal (JSON/CSV files, ~100MB per collection) |
| **Network** | Outbound HTTPS to XATbackend portal |
| **Instances** | 2 VMs for comparative testing |

### 1.2 Budget Constraints

**CRITICAL**: Initial deployment must use **OCI Always Free Tier** only.

**Always Free Resources Available**:
- 2 AMD-based Compute VMs (VM.Standard.E2.1.Micro) OR
- Up to 4 Arm-based Ampere A1 Compute instances (3,000 OCPU hours/month)
- 200 GB total Block Volume storage
- 10 GB Object Storage
- 10 TB/month Outbound Data Transfer
- 1 Load Balancer (10 Mbps)
- Monitoring and Logging (basic)

### 1.3 Security Requirements

- Network isolation for test VMs
- Secure outbound connectivity to XATbackend
- IAM least-privilege access
- No public IP exposure (use NAT Gateway or bastion)

---

## 2. Architecture Design

### 2.1 Compartment Structure

Following Oracle best practices for resource isolation and access control:

```
Root Compartment (Tenancy)
│
└── PerfAnalysis (Parent Compartment)
    │
    ├── PerfTest-Network
    │   └── VCN, Subnets, Gateways, Security Lists
    │
    ├── PerfTest-Compute
    │   └── VM instances, Boot volumes, Block volumes
    │
    └── PerfTest-Security
        └── Dynamic groups, Vault secrets (future)
```

**Rationale**:
- **PerfAnalysis**: Top-level compartment for all performance analysis resources
- **PerfTest-Network**: Isolates networking resources for security and management
- **PerfTest-Compute**: Contains compute instances, enables compute-specific policies
- **PerfTest-Security**: Security resources (expandable for Vault integration)

### 2.2 VCN Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    VCN: perftest-vcn (10.0.0.0/16)                      │
│                    Region: Your Home Region                              │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                    Availability Domain 1                         │    │
│  │                                                                  │    │
│  │  ┌──────────────────────┐    ┌──────────────────────┐           │    │
│  │  │  Public Subnet       │    │  Private Subnet      │           │    │
│  │  │  10.0.1.0/24         │    │  10.0.10.0/24        │           │    │
│  │  │                      │    │                      │           │    │
│  │  │  ┌────────────────┐  │    │  ┌────────────────┐  │           │    │
│  │  │  │ Bastion Host   │  │    │  │ perftest-vm-01 │  │           │    │
│  │  │  │ (Optional)     │  │    │  │ (pcc client)   │  │           │    │
│  │  │  └────────────────┘  │    │  └────────────────┘  │           │    │
│  │  │                      │    │                      │           │    │
│  │  │                      │    │  ┌────────────────┐  │           │    │
│  │  │                      │    │  │ perftest-vm-02 │  │           │    │
│  │  │                      │    │  │ (pcc client)   │  │           │    │
│  │  │                      │    │  └────────────────┘  │           │    │
│  │  │                      │    │                      │           │    │
│  │  │  Route: IGW          │    │  Route: NAT GW       │           │    │
│  │  └──────────────────────┘    └──────────────────────┘           │    │
│  │                                                                  │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                      │
│  │ Internet    │  │ NAT         │  │ Service     │                      │
│  │ Gateway     │  │ Gateway     │  │ Gateway     │                      │
│  └─────────────┘  └─────────────┘  └─────────────┘                      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.3 CIDR Planning

| Resource | CIDR Block | Purpose |
|----------|------------|---------|
| VCN | 10.0.0.0/16 | Main VCN (65,536 addresses) |
| Public Subnet | 10.0.1.0/24 | Bastion access (if needed) |
| Private Subnet | 10.0.10.0/24 | Performance test VMs |
| Reserved | 10.0.20.0/24 | Future expansion |
| Reserved | 10.0.30.0/24 | Future database tier |

### 2.4 Compute Instance Specifications (Free Tier)

**Option A: AMD-based (Recommended for simplicity)**

| Attribute | perftest-vm-01 | perftest-vm-02 |
|-----------|----------------|----------------|
| **Shape** | VM.Standard.E2.1.Micro | VM.Standard.E2.1.Micro |
| **OCPU** | 1 (1/8th burstable) | 1 (1/8th burstable) |
| **Memory** | 1 GB | 1 GB |
| **Network** | 480 Mbps | 480 Mbps |
| **Boot Volume** | 50 GB (Always Free) | 50 GB (Always Free) |
| **OS** | Oracle Linux 8 | Oracle Linux 8 |
| **Cost** | FREE | FREE |

**Option B: ARM-based Ampere A1 (More powerful)**

| Attribute | perftest-vm-01 | perftest-vm-02 |
|-----------|----------------|----------------|
| **Shape** | VM.Standard.A1.Flex | VM.Standard.A1.Flex |
| **OCPU** | 1 | 1 |
| **Memory** | 6 GB | 6 GB |
| **Network** | 1 Gbps | 1 Gbps |
| **Boot Volume** | 50 GB (Always Free) | 50 GB (Always Free) |
| **OS** | Oracle Linux 8 (aarch64) | Oracle Linux 8 (aarch64) |
| **Cost** | FREE (within 3000 OCPU-hours/month) | FREE |

**Recommendation**: Use **Option B (ARM Ampere A1)** for better performance and memory, which benefits sysbench and pcc workloads.

---

## 3. Security Configuration

### 3.1 Network Security Groups (NSGs)

**NSG: nsg-perftest-vms**

| Direction | Protocol | Source/Dest | Port | Description |
|-----------|----------|-------------|------|-------------|
| Ingress | TCP | 10.0.1.0/24 | 22 | SSH from bastion subnet |
| Ingress | ICMP | 10.0.0.0/16 | All | ICMP within VCN |
| Egress | TCP | 0.0.0.0/0 | 443 | HTTPS to XATbackend |
| Egress | TCP | 0.0.0.0/0 | 80 | HTTP (package updates) |
| Egress | UDP | 0.0.0.0/0 | 53 | DNS resolution |
| Egress | TCP | OCI Services | All | OCI service network |

**NSG: nsg-bastion** (if using bastion)

| Direction | Protocol | Source/Dest | Port | Description |
|-----------|----------|-------------|------|-------------|
| Ingress | TCP | Your IP | 22 | SSH from admin IP only |
| Egress | TCP | 10.0.10.0/24 | 22 | SSH to private subnet |

### 3.2 Security List (Default - Backup)

The private subnet security list provides defense in depth:

```hcl
# Ingress Rules
ingress_security_rules {
  protocol    = "6"  # TCP
  source      = "10.0.1.0/24"
  tcp_options {
    min = 22
    max = 22
  }
  description = "SSH from bastion"
}

# Egress Rules
egress_security_rules {
  protocol    = "all"
  destination = "0.0.0.0/0"
  description = "Allow all outbound"
}
```

### 3.3 IAM Policies

**Group: PerfTest-Admins**
```
Allow group PerfTest-Admins to manage all-resources in compartment PerfAnalysis
```

**Group: PerfTest-Users** (read-only for monitoring)
```
Allow group PerfTest-Users to read all-resources in compartment PerfAnalysis
Allow group PerfTest-Users to use instances in compartment PerfTest-Compute
```

**Dynamic Group: PerfTest-Instances** (for instance principals)
```
ALL {instance.compartment.id = '<PerfTest-Compute-OCID>'}
```

**Policy for Instance Principals** (future - object storage upload)
```
Allow dynamic-group PerfTest-Instances to manage objects in compartment PerfAnalysis
  where target.bucket.name = 'perftest-results'
```

---

## 4. Implementation Plan

### Phase 1: Foundation (Day 1)

| Step | Task | Resource | Details |
|------|------|----------|---------|
| 1.1 | Create parent compartment | PerfAnalysis | Under root or designated parent |
| 1.2 | Create child compartments | PerfTest-Network, PerfTest-Compute, PerfTest-Security | Under PerfAnalysis |
| 1.3 | Create IAM group | PerfTest-Admins | Add your user |
| 1.4 | Create IAM policies | See section 3.3 | Attach to PerfAnalysis |

### Phase 2: Networking (Day 1-2)

| Step | Task | Resource | Details |
|------|------|----------|---------|
| 2.1 | Create VCN | perftest-vcn | CIDR: 10.0.0.0/16 |
| 2.2 | Create Internet Gateway | perftest-igw | Attach to VCN |
| 2.3 | Create NAT Gateway | perftest-natgw | For private subnet outbound |
| 2.4 | Create Service Gateway | perftest-sgw | For OCI services |
| 2.5 | Create Public Subnet | public-subnet | 10.0.1.0/24, route to IGW |
| 2.6 | Create Private Subnet | private-subnet | 10.0.10.0/24, route to NAT GW |
| 2.7 | Create Route Tables | rt-public, rt-private | Configure routes |
| 2.8 | Create NSGs | nsg-perftest-vms, nsg-bastion | See section 3.1 |

### Phase 3: Compute (Day 2-3)

| Step | Task | Resource | Details |
|------|------|----------|---------|
| 3.1 | Generate SSH key pair | Local | `ssh-keygen -t ed25519` |
| 3.2 | Create VM 1 | perftest-vm-01 | ARM A1.Flex, 1 OCPU, 6GB |
| 3.3 | Create VM 2 | perftest-vm-02 | ARM A1.Flex, 1 OCPU, 6GB |
| 3.4 | Attach NSG | Both VMs | nsg-perftest-vms |
| 3.5 | Configure cloud-init | Both VMs | Install dependencies |

### Phase 4: Software Setup (Day 3-4)

| Step | Task | Details |
|------|------|---------|
| 4.1 | SSH to VMs | Via bastion or Cloud Shell |
| 4.2 | Install Go | Required for pcc |
| 4.3 | Build pcc | Clone perfcollector2, `make pcc` |
| 4.4 | Install sysbench | `sudo dnf install sysbench` |
| 4.5 | Configure pcc | Set API key, XATbackend URL |
| 4.6 | Test connectivity | Verify HTTPS to portal |

### Phase 5: Validation (Day 4-5)

| Step | Task | Details |
|------|------|---------|
| 5.1 | Run test collection | `pcc` with short duration |
| 5.2 | Process to CSV | `pcprocess` |
| 5.3 | Upload to XATbackend | Verify data appears |
| 5.4 | Run synchronized test | Both VMs simultaneously |
| 5.5 | Document results | Update project docs |

---

## 5. Terraform Module Structure

Create the following structure in `OCI/terraform/`:

```
OCI/terraform/
├── modules/
│   ├── compartment/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vcn/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── cloud-init.yaml
│   │
│   └── security/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/
    └── perftest/
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        ├── outputs.tf
        └── backend.tf
```

### Key Terraform Files

**modules/compartment/main.tf**
```hcl
resource "oci_identity_compartment" "perfanalysis" {
  compartment_id = var.parent_compartment_id
  name           = "PerfAnalysis"
  description    = "Performance Analysis and Testing"
  enable_delete  = true
}

resource "oci_identity_compartment" "network" {
  compartment_id = oci_identity_compartment.perfanalysis.id
  name           = "PerfTest-Network"
  description    = "Network resources for performance testing"
}

resource "oci_identity_compartment" "compute" {
  compartment_id = oci_identity_compartment.perfanalysis.id
  name           = "PerfTest-Compute"
  description    = "Compute instances for performance testing"
}

resource "oci_identity_compartment" "security" {
  compartment_id = oci_identity_compartment.perfanalysis.id
  name           = "PerfTest-Security"
  description    = "Security resources"
}
```

**modules/compute/cloud-init.yaml**
```yaml
#cloud-config
package_update: true
package_upgrade: true

packages:
  - git
  - make
  - sysbench
  - curl
  - jq

runcmd:
  # Install Go (for ARM)
  - wget https://go.dev/dl/go1.21.6.linux-arm64.tar.gz
  - tar -C /usr/local -xzf go1.21.6.linux-arm64.tar.gz
  - echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile.d/go.sh

  # Create pcc user
  - useradd -m -s /bin/bash pcc

  # Clone and build perfcollector2
  - sudo -u pcc git clone https://github.com/businessperformancetuning/perfcollector2.git /home/pcc/perfcollector2
  - cd /home/pcc/perfcollector2 && sudo -u pcc /usr/local/go/bin/go build -o bin/pcc ./cmd/pcc

  # Set up pcc environment
  - echo 'export PATH=$PATH:/home/pcc/perfcollector2/bin' >> /home/pcc/.bashrc

final_message: "PerfTest VM ready after $UPTIME seconds"
```

---

## 6. Cost Analysis

### Free Tier Resources Used

| Resource | Quantity | Monthly Cost |
|----------|----------|--------------|
| Ampere A1 Compute (2 x 1 OCPU, 6GB) | 1,440 hours | $0 (within 3,000 hours) |
| Boot Volumes (2 x 50 GB) | 100 GB | $0 (within 200 GB) |
| NAT Gateway | 1 | $0* |
| Object Storage | <10 GB | $0 (within 10 GB) |
| Outbound Data | <10 TB | $0 (within 10 TB) |
| **Total** | | **$0/month** |

*Note: NAT Gateway is free, but data processing may incur charges if exceeding limits.

### Cost Optimization Tips

1. **Stop instances when not in use** - Free tier hours accumulate even when stopped
2. **Use scheduled start/stop** - OCI Functions can automate this
3. **Monitor usage** - Set up budget alerts at $0.01 threshold
4. **Use Reserved Public IPs sparingly** - Only 1 free per tenancy

---

## 7. Monitoring & Operations

### 7.1 Monitoring Setup (Free Tier)

- **OCI Monitoring**: Enable default metrics for compute
- **Alarms**: Create alarm for CPU > 80% sustained
- **Notifications**: Email alerts via ONS topic

### 7.2 Operational Runbooks

| Task | Command/Process |
|------|-----------------|
| SSH to VM | `ssh -J bastion opc@<private-ip>` or OCI Cloud Shell |
| Start pcc collection | `PCC_DURATION=1h PCC_FREQUENCY=5s pcc` |
| Run sysbench CPU | `sysbench cpu --threads=1 --time=300 run` |
| Check VM status | OCI Console > Compute > Instances |
| View metrics | OCI Console > Monitoring > Metrics Explorer |

### 7.3 Backup Strategy

- **Boot Volume Backups**: Manual backups before major changes
- **Data Export**: CSV files uploaded to XATbackend serve as backup
- **Terraform State**: Store in OCI Object Storage (future)

---

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Free tier limits exceeded | Low | Medium | Monitor usage, set alerts |
| VM unavailable | Low | Low | Use separate ADs if available |
| Network connectivity issues | Low | Medium | Test connectivity early |
| Security breach | Low | High | NSGs, no public IPs, audit logs |
| Data loss | Low | Low | Regular uploads to XATbackend |

---

## 9. Success Criteria

| Criterion | Target | Measurement |
|-----------|--------|-------------|
| Infrastructure deployed | 100% | All resources provisioned |
| VMs operational | 2 VMs running | OCI Console verification |
| pcc functional | Collect metrics | Successful JSON output |
| XATbackend upload | Data visible | Portal shows data |
| Cost | $0/month | Billing dashboard |
| Security | No public exposure | NSG audit |

---

## 10. Next Steps

1. **Immediate**: Create OCI account (if not existing) with Always Free tier
2. **Day 1**: Implement Phase 1 (Compartments) and Phase 2 (Networking)
3. **Day 2-3**: Implement Phase 3 (Compute) and Phase 4 (Software)
4. **Day 4-5**: Validate end-to-end data flow
5. **Future**:
   - Add Terraform automation
   - Implement instance principals for automated uploads
   - Consider OCI Functions for scheduled benchmarks

---

## Appendix A: OCI CLI Commands

```bash
# Set up OCI CLI config
oci setup config

# Create compartment
oci iam compartment create \
  --compartment-id <parent-ocid> \
  --name "PerfAnalysis" \
  --description "Performance Analysis"

# List availability domains
oci iam availability-domain list --compartment-id <tenancy-ocid>

# Create VCN
oci network vcn create \
  --compartment-id <network-compartment-ocid> \
  --cidr-block "10.0.0.0/16" \
  --display-name "perftest-vcn"

# List compute shapes (free tier)
oci compute shape list \
  --compartment-id <compute-compartment-ocid> \
  --availability-domain <ad-name> \
  | jq '.data[] | select(.shape | contains("Micro") or contains("A1"))'
```

---

## Appendix B: References

- [OCI Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [OCI Compartment Best Practices](https://docs.oracle.com/en-us/iaas/Content/Identity/compartments/managingcompartments.htm)
- [OCI VCN Overview](https://docs.oracle.com/en-us/iaas/Content/Network/Concepts/overview.htm)
- [OCI Security Best Practices](https://docs.oracle.com/en-us/iaas/Content/Security/Concepts/security_guide.htm)
- [Terraform OCI Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)

---

**Document Status**: Ready for Implementation
**Prepared By**: OCI Architect Professional Agent
**Review Required**: Solutions Architect, Security Architect
