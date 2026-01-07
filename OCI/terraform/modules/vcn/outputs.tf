# Outputs for VCN Module

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.perftest.id
}

output "vcn_cidr" {
  description = "CIDR block of the VCN"
  value       = oci_core_vcn.perftest.cidr_blocks[0]
}

output "public_subnet_id" {
  description = "OCID of the public subnet"
  value       = oci_core_subnet.public.id
}

output "private_subnet_id" {
  description = "OCID of the private subnet"
  value       = oci_core_subnet.private.id
}

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway"
  value       = oci_core_internet_gateway.perftest.id
}

output "nat_gateway_id" {
  description = "OCID of the NAT Gateway"
  value       = oci_core_nat_gateway.perftest.id
}

output "service_gateway_id" {
  description = "OCID of the Service Gateway"
  value       = oci_core_service_gateway.perftest.id
}

output "public_security_list_id" {
  description = "OCID of the public subnet security list"
  value       = oci_core_security_list.public.id
}

output "private_security_list_id" {
  description = "OCID of the private subnet security list"
  value       = oci_core_security_list.private.id
}

output "subnet_ids" {
  description = "Map of subnet IDs"
  value = {
    public  = oci_core_subnet.public.id
    private = oci_core_subnet.private.id
  }
}
