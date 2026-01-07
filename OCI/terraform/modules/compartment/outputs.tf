# Outputs for Compartment Module

output "perfanalysis_compartment_id" {
  description = "OCID of the PerfAnalysis parent compartment"
  value       = oci_identity_compartment.perfanalysis.id
}

output "network_compartment_id" {
  description = "OCID of the Network compartment"
  value       = oci_identity_compartment.network.id
}

output "compute_compartment_id" {
  description = "OCID of the Compute compartment"
  value       = oci_identity_compartment.compute.id
}

output "security_compartment_id" {
  description = "OCID of the Security compartment"
  value       = oci_identity_compartment.security.id
}

output "compartment_ids" {
  description = "Map of all compartment IDs"
  value = {
    perfanalysis = oci_identity_compartment.perfanalysis.id
    network      = oci_identity_compartment.network.id
    compute      = oci_identity_compartment.compute.id
    security     = oci_identity_compartment.security.id
  }
}
