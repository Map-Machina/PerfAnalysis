# Outputs for PerfTest Environment

# Compartment Outputs
output "compartment_ids" {
  description = "Map of compartment OCIDs"
  value       = module.compartments.compartment_ids
}

# Network Outputs
output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.vcn.vcn_id
}

output "subnet_ids" {
  description = "Map of subnet OCIDs"
  value       = module.vcn.subnet_ids
}

output "nsg_id" {
  description = "OCID of the PerfTest VMs NSG"
  value       = oci_core_network_security_group.perftest_vms.id
}

# Compute Outputs
output "instance_ids" {
  description = "List of instance OCIDs"
  value       = module.compute.instance_ids
}

output "instance_private_ips" {
  description = "List of private IP addresses"
  value       = module.compute.instance_private_ips
}

output "instance_details" {
  description = "Detailed instance information"
  value       = module.compute.instance_details
}

# Connection Information
output "ssh_connection_info" {
  description = "SSH connection instructions"
  value       = <<-EOT

    ============================================================
    PerfTest VM Connection Instructions
    ============================================================

    The VMs are in a private subnet without public IPs.
    Use one of these methods to connect:

    Option 1: OCI Cloud Shell (Recommended for Free Tier)
    -----------------------------------------------------
    1. Go to OCI Console > Cloud Shell (top-right icon)
    2. SSH to private IP:
       ${join("\n       ", [for name, details in module.compute.instance_details : "ssh opc@${details.private_ip}  # ${name}"])}

    Option 2: Bastion Service (Additional Setup Required)
    -----------------------------------------------------
    1. Create OCI Bastion in public subnet
    2. Create session to target instance
    3. Use provided SSH command

    Option 3: VPN or FastConnect
    ----------------------------
    Configure site-to-site VPN or FastConnect for direct access

    ============================================================
    Instance Details
    ============================================================
    ${join("\n    ", [for name, details in module.compute.instance_details : "${name}: ${details.private_ip} (${details.shape})"])}

    ============================================================
    Post-Deployment Steps
    ============================================================
    1. SSH to each VM
    2. Switch to pcc user: sudo su - pcc
    3. Verify pcc installation: pcc --help
    4. Run benchmark: ./run_benchmark.sh
    5. Process results and upload to XATbackend

  EOT
}
