# PerfTest Environment - Main Configuration
# Deploys OCI infrastructure for performance testing using Always Free resources

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

# OCI Provider Configuration
provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Compartment Module
module "compartments" {
  source = "../../modules/compartment"

  parent_compartment_id   = var.tenancy_ocid
  parent_compartment_name = "PerfAnalysis"
  environment             = "PerfTest"
  enable_delete           = true

  common_tags = var.common_tags
}

# VCN Module
module "vcn" {
  source = "../../modules/vcn"

  compartment_id      = module.compartments.network_compartment_id
  name_prefix         = "perftest"
  vcn_cidr            = var.vcn_cidr
  vcn_dns_label       = "perftest"
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  admin_cidr          = var.admin_cidr

  common_tags = var.common_tags

  depends_on = [module.compartments]
}

# Network Security Group for PerfTest VMs
resource "oci_core_network_security_group" "perftest_vms" {
  compartment_id = module.compartments.network_compartment_id
  vcn_id         = module.vcn.vcn_id
  display_name   = "nsg-perftest-vms"

  freeform_tags = var.common_tags
}

# NSG Rules for PerfTest VMs
resource "oci_core_network_security_group_security_rule" "perftest_ssh_ingress" {
  network_security_group_id = oci_core_network_security_group.perftest_vms.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  description               = "SSH from public subnet (bastion)"

  source      = var.public_subnet_cidr
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "perftest_icmp_ingress" {
  network_security_group_id = oci_core_network_security_group.perftest_vms.id
  direction                 = "INGRESS"
  protocol                  = "1" # ICMP
  description               = "ICMP within VCN"

  source      = var.vcn_cidr
  source_type = "CIDR_BLOCK"

  icmp_options {
    type = 3
    code = 4
  }
}

resource "oci_core_network_security_group_security_rule" "perftest_https_egress" {
  network_security_group_id = oci_core_network_security_group.perftest_vms.id
  direction                 = "EGRESS"
  protocol                  = "6" # TCP
  description               = "HTTPS outbound (XATbackend, package repos)"

  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "perftest_http_egress" {
  network_security_group_id = oci_core_network_security_group.perftest_vms.id
  direction                 = "EGRESS"
  protocol                  = "6" # TCP
  description               = "HTTP outbound (package repos)"

  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 80
      max = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "perftest_dns_egress" {
  network_security_group_id = oci_core_network_security_group.perftest_vms.id
  direction                 = "EGRESS"
  protocol                  = "17" # UDP
  description               = "DNS resolution"

  destination      = "0.0.0.0/0"
  destination_type = "CIDR_BLOCK"

  udp_options {
    destination_port_range {
      min = 53
      max = 53
    }
  }
}

# Compute Module
module "compute" {
  source = "../../modules/compute"

  compartment_id     = module.compartments.compute_compartment_id
  tenancy_id         = var.tenancy_ocid
  subnet_id          = module.vcn.private_subnet_id
  name_prefix        = "perftest"
  instance_count     = var.instance_count
  instance_shape     = var.instance_shape
  instance_ocpus     = var.instance_ocpus
  instance_memory_gb = var.instance_memory_gb
  boot_volume_size_gb = var.boot_volume_size_gb
  assign_public_ip   = false
  ssh_public_key     = var.ssh_public_key
  nsg_ids            = [oci_core_network_security_group.perftest_vms.id]
  go_version         = "1.21.6"
  perfcollector_repo = "https://github.com/businessperformancetuning/perfcollector2.git"

  common_tags = var.common_tags

  depends_on = [module.vcn]
}
