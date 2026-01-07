# Outputs for Compute Module

output "instance_ids" {
  description = "List of instance OCIDs"
  value       = oci_core_instance.perftest[*].id
}

output "instance_private_ips" {
  description = "List of private IP addresses"
  value       = oci_core_instance.perftest[*].private_ip
}

output "instance_public_ips" {
  description = "List of public IP addresses (if assigned)"
  value       = oci_core_instance.perftest[*].public_ip
}

output "instance_names" {
  description = "List of instance display names"
  value       = oci_core_instance.perftest[*].display_name
}

output "instance_details" {
  description = "Map of instance details"
  value = {
    for idx, instance in oci_core_instance.perftest : instance.display_name => {
      id                  = instance.id
      private_ip          = instance.private_ip
      public_ip           = instance.public_ip
      availability_domain = instance.availability_domain
      shape               = instance.shape
      state               = instance.state
    }
  }
}

output "image_id" {
  description = "OCID of the image used"
  value       = local.image_id
}
