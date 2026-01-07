# OCI Implementation Post-Mortem: Knowledge Gap Analysis

**Date**: 2026-01-07
**Status**: VMs Terminated - Retry Scheduled for Tomorrow
**Objective**: Identify why the agents believed the implementation would work

---

## Executive Summary

The OCI infrastructure deployment experienced multiple failures stemming from **flawed assumptions** about how OCI differs from other cloud platforms. The agents applied general cloud knowledge without accounting for OCI-specific behaviors in three critical areas:

1. **OCI Bastion Service networking model**
2. **Cloud-init interaction with OCI's opc user provisioning**
3. **Memory requirements for package management on minimal instances**

This report analyzes **why the agents thought it would work**, not just what went wrong.

---

## Failure 1: Bastion Service Security List Configuration

### What the Agents Believed

The agents configured security lists to allow SSH ingress from the **public subnet CIDR (10.0.1.0/24)**, believing that:

> "The bastion resides in a public subnet and will SSH into VMs in the private subnet. Therefore, we need to allow SSH from the public subnet."

This follows the **traditional bastion host model** used in AWS, Azure, and on-premises environments.

### Why This Belief Was Wrong

OCI's Bastion Service does **not** operate like a traditional bastion host:

| Traditional Bastion Host | OCI Bastion Service |
|--------------------------|---------------------|
| Runs as a VM in public subnet | Managed service, no VM required |
| SSH traffic originates from bastion VM's IP | Creates a **private endpoint** in the TARGET subnet |
| Security rules allow ingress from public subnet | Security rules must allow ingress from **private subnet** |

**OCI Bastion Service Architecture:**
```
User → Bastion Service → Private Endpoint (10.0.10.144) → Target VM (10.0.10.151)
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                         This IP is IN the private subnet!
```

The bastion's private endpoint IP (10.0.10.144) was in the private subnet (10.0.10.0/24), but the security list only allowed SSH from 10.0.1.0/24 (public subnet).

### Knowledge Gap

**The agents did not know that OCI Bastion Service creates a private endpoint within the target subnet itself.**

This is a fundamental architectural difference from:
- AWS Session Manager (uses SSM agent, no network ingress needed)
- Azure Bastion (uses a dedicated subnet, not the target subnet)
- Traditional SSH jump boxes (in separate public subnet)

### Source of the Flawed Assumption

The agents extrapolated from generic cloud security patterns without consulting OCI-specific documentation about how the Bastion Service routes traffic.

---

## Failure 2: Cloud-Init `users` Block Breaking SSH Key Provisioning

### What the Agents Believed

The agents added a `users:` block to cloud-init to create a `pcc` user:

```yaml
users:
  - name: pcc
    groups: wheel
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
```

The belief was:

> "Cloud-init will create the pcc user in addition to the default opc user. Both users will have SSH keys configured from instance metadata."

### Why This Belief Was Wrong

In OCI's Oracle Linux images, the SSH key provisioning for the `opc` user happens through a specific cloud-init process. When you add a custom `users:` block:

1. Cloud-init interprets this as "these are the users I should manage"
2. The default user (`opc`) may not receive its SSH keys properly
3. The order of operations in cloud-init means `write_files` with `owner: pcc:pcc` fails because `pcc` doesn't exist yet

**OCI's user provisioning flow:**
```
1. Base image has opc user (no SSH keys yet)
2. Cloud-init reads ssh_authorized_keys from instance metadata
3. Cloud-init configures opc's ~/.ssh/authorized_keys
4. Custom cloud-init users: block INTERFERES with step 3
```

### Knowledge Gap

**The agents did not understand that OCI's default user (opc) has a special provisioning path that custom cloud-init `users:` blocks can disrupt.**

This is OCI-specific behavior. In AWS, you can freely add users via cloud-init without affecting the ec2-user. In Azure, the same applies to the azureuser.

### Source of the Flawed Assumption

The agents treated cloud-init as cloud-agnostic, not realizing that each cloud provider has custom integrations that affect how default users are provisioned.

---

## Failure 3: Memory Requirements for Package Installation

### What the Agents Believed

The initial configuration used `VM.Standard.E2.1.Micro` instances with **1GB RAM**, believing:

> "1GB is sufficient for a minimal Linux instance. We'll disable package_update and package_upgrade to reduce memory usage during boot."

After OOM errors, the agents upgraded to `VM.Standard.E5.Flex` with **2GB RAM**, believing:

> "2GB should be plenty for dnf/yum package installation. We've disabled updates, so only sysbench needs to be installed."

### Why This Belief Was Wrong

The agents failed to account for:

1. **DNF's memory footprint**: DNF (Dandified YUM) in Oracle Linux 8 is significantly more memory-hungry than yum in OL7
2. **RPM database operations**: Even a simple package install requires loading the RPM database
3. **Metadata caching**: DNF downloads and parses repository metadata before any install
4. **Competing memory pressure**: Cloud-init, systemd services, and Oracle Cloud Agent all consume memory at boot

**Actual memory during dnf install:**
```
Base system:     ~400MB
DNF metadata:    ~300MB
Package install: ~200MB
Oracle Agent:    ~150MB
Cloud-init:      ~100MB
------------------------
Total needed:    ~1150MB minimum (peak can exceed 1500MB)
```

With 2GB total and only ~1600MB available (kernel reserves ~400MB), the system was at the edge of OOM during package operations.

### Knowledge Gap

**The agents did not know the actual memory requirements for DNF package operations on Oracle Linux 8, especially during the constrained boot environment.**

The agents also did not consider:
- Using `--setopt=install_weak_deps=False` to reduce memory
- Pre-installing sysbench in a custom image
- Using swap space to handle memory peaks
- Sequencing operations to avoid concurrent memory pressure

### Source of the Flawed Assumption

The agents applied general Linux knowledge ("1GB is enough for a minimal server") without testing the specific workload or consulting Oracle Linux performance documentation.

---

## Failure 4: Assuming perfcollector2 Would Be Pre-Installed

### What the Agents Believed

The cloud-init configuration included scripts referencing `/home/pcc/perfcollector2/bin/pcc`, believing:

> "We'll install Go and clone perfcollector2 during cloud-init, so the binaries will be available."

But the actual cloud-init was "minimized" to avoid OOM, removing the Go installation.

### Why This Belief Was Wrong

The agents created a **dependency without fulfillment**:

1. Removed Go installation to save memory
2. Kept scripts that depend on compiled Go binaries
3. No fallback or check for binary existence
4. No documentation of manual installation steps required

**The configuration assumed a step that was removed:**
```yaml
# What was removed (to save memory):
# - Install Go
# - Clone perfcollector2
# - Build binaries

# What was kept (now broken):
- path: /home/pcc/run_benchmark.sh
    content: |
      /home/pcc/perfcollector2/bin/pcc &  # <-- This doesn't exist!
```

### Knowledge Gap

**The agents did not maintain consistency between the "minimized" cloud-init and the scripts that depended on removed components.**

### Source of the Flawed Assumption

Incremental changes to fix one problem (OOM) created new problems (missing dependencies) that weren't caught because no end-to-end validation was performed.

---

## Root Cause Summary

| Failure | Flawed Belief | Reality | Knowledge Gap |
|---------|---------------|---------|---------------|
| Security Lists | Bastion is in public subnet, SSH comes from there | Bastion creates private endpoint in target subnet | OCI Bastion Service architecture |
| SSH Keys | Cloud-init users: block adds users alongside opc | users: block can interfere with opc key provisioning | OCI's opc user provisioning integration |
| Memory | 2GB is plenty for package installation | DNF needs 1.5GB+ peak during operations | Oracle Linux 8 DNF memory requirements |
| Dependencies | perfcollector2 would be installed | Go installation was removed to save memory | Configuration consistency |

---

## Recommendations for Tomorrow's Retry

### 1. Use Adequate Memory

```hcl
instance_memory_gb = 4  # Minimum for reliable package operations
```

Or use A1.Flex shape which has better memory-to-cost ratio in free tier.

### 2. Pre-Install Software in Custom Image

Instead of installing at boot time:
1. Create a base VM manually
2. Install all required software (Go, sysbench, perfcollector2)
3. Create a custom image from that VM
4. Use the custom image in Terraform

### 3. Fix Security List for Bastion Service

Already fixed in Terraform, but verify:
```hcl
# Must allow SSH from private subnet for Bastion Service
ingress_security_rules {
  source = var.private_subnet_cidr  # 10.0.10.0/24
  ...
}
```

### 4. Simplify Cloud-Init

Remove all complex user setup. Keep it minimal:
```yaml
#cloud-config
package_update: false
package_upgrade: false

runcmd:
  - echo "Instance ready" > /tmp/cloud-init-complete
```

### 5. Install Software Post-Boot

After SSH access is confirmed:
1. SSH into VM
2. Install sysbench manually
3. Install perfcollector2 manually
4. Run benchmarks

### 6. Document OCI-Specific Behaviors

Create OCI-specific documentation covering:
- Bastion Service networking model
- Oracle Linux cloud-init behaviors
- Memory requirements for common operations
- opc user provisioning process

---

## Lessons Learned

1. **Cloud platforms are not interchangeable** - OCI has unique behaviors that differ from AWS/Azure
2. **Test incrementally** - Verify SSH access before adding complexity
3. **Memory matters at boot** - Boot-time operations have different memory profiles than steady-state
4. **Maintain configuration consistency** - When removing one component, check all dependencies
5. **Consult platform-specific documentation** - Generic cloud knowledge is insufficient

---

## Agents Involved and Their Assumptions

| Agent | Assumption Made | Should Have Known |
|-------|-----------------|-------------------|
| Solutions Architect | Standard bastion pattern applies | OCI Bastion Service has unique architecture |
| DevOps Engineer | 2GB sufficient for dnf | Should test or consult OL8 requirements |
| Linux Systems Engineer | cloud-init users: is universal | OCI has custom opc provisioning |
| Go Backend Developer | perfcollector2 would be available | Dependencies were removed in earlier changes |

---

*Report generated after analysis of failed OCI deployment attempts on 2026-01-07*
