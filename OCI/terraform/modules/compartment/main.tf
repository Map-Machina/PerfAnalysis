# OCI Compartment Module
# Creates hierarchical compartment structure for PerfAnalysis

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

# Parent Compartment: PerfAnalysis
resource "oci_identity_compartment" "perfanalysis" {
  compartment_id = var.parent_compartment_id
  name           = var.parent_compartment_name
  description    = "Performance Analysis and Testing - Parent Compartment"
  enable_delete  = var.enable_delete

  freeform_tags = merge(var.common_tags, {
    "Purpose" = "Performance Analysis"
    "Project" = "PerfAnalysis"
  })
}

# Child Compartment: Network
resource "oci_identity_compartment" "network" {
  compartment_id = oci_identity_compartment.perfanalysis.id
  name           = "${var.environment}-Network"
  description    = "Network resources for performance testing (VCN, subnets, gateways)"
  enable_delete  = var.enable_delete

  freeform_tags = merge(var.common_tags, {
    "Purpose" = "Networking"
    "Tier"    = "Infrastructure"
  })
}

# Child Compartment: Compute
resource "oci_identity_compartment" "compute" {
  compartment_id = oci_identity_compartment.perfanalysis.id
  name           = "${var.environment}-Compute"
  description    = "Compute instances for performance testing"
  enable_delete  = var.enable_delete

  freeform_tags = merge(var.common_tags, {
    "Purpose" = "Compute"
    "Tier"    = "Application"
  })
}

# Child Compartment: Security
resource "oci_identity_compartment" "security" {
  compartment_id = oci_identity_compartment.perfanalysis.id
  name           = "${var.environment}-Security"
  description    = "Security resources (Vault, keys, policies)"
  enable_delete  = var.enable_delete

  freeform_tags = merge(var.common_tags, {
    "Purpose" = "Security"
    "Tier"    = "Security"
  })
}
