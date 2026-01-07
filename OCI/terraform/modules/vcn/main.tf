# OCI VCN Module
# Creates VCN with public and private subnets for performance testing

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

# Virtual Cloud Network
resource "oci_core_vcn" "perftest" {
  compartment_id = var.compartment_id
  cidr_blocks    = [var.vcn_cidr]
  display_name   = "${var.name_prefix}-vcn"
  dns_label      = var.vcn_dns_label

  freeform_tags = var.common_tags
}

# Internet Gateway (for public subnet)
resource "oci_core_internet_gateway" "perftest" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.perftest.id
  display_name   = "${var.name_prefix}-igw"
  enabled        = true

  freeform_tags = var.common_tags
}

# NAT Gateway (for private subnet outbound)
resource "oci_core_nat_gateway" "perftest" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.perftest.id
  display_name   = "${var.name_prefix}-natgw"
  block_traffic  = false

  freeform_tags = var.common_tags
}

# Service Gateway (for OCI services)
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "perftest" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.perftest.id
  display_name   = "${var.name_prefix}-sgw"

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }

  freeform_tags = var.common_tags
}

# Route Table for Public Subnet
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.perftest.id
  display_name   = "${var.name_prefix}-rt-public"

  route_rules {
    network_entity_id = oci_core_internet_gateway.perftest.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    description       = "Internet access via IGW"
  }

  freeform_tags = var.common_tags
}

# Route Table for Private Subnet
resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.perftest.id
  display_name   = "${var.name_prefix}-rt-private"

  route_rules {
    network_entity_id = oci_core_nat_gateway.perftest.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    description       = "Outbound via NAT Gateway"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.perftest.id
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    description       = "OCI Services via Service Gateway"
  }

  freeform_tags = var.common_tags
}

# Security List for Public Subnet
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.perftest.id
  display_name   = "${var.name_prefix}-sl-public"

  # Ingress: SSH from allowed IPs
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.admin_cidr
    source_type = "CIDR_BLOCK"
    description = "SSH from admin CIDR"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: ICMP
  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    description = "ICMP for connectivity testing"

    icmp_options {
      type = 3
      code = 4
    }
  }

  # Egress: All traffic
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    description      = "Allow all outbound"
  }

  freeform_tags = var.common_tags
}

# Security List for Private Subnet
resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.perftest.id
  display_name   = "${var.name_prefix}-sl-private"

  # Ingress: SSH from public subnet (traditional bastion host)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.public_subnet_cidr
    source_type = "CIDR_BLOCK"
    description = "SSH from bastion public subnet"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: SSH from private subnet (OCI Bastion Service private endpoint)
  # The OCI Bastion Service creates a private endpoint within the target subnet
  # and SSH traffic originates from that private endpoint IP
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = var.private_subnet_cidr
    source_type = "CIDR_BLOCK"
    description = "SSH from bastion private endpoint"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Ingress: ICMP within VCN
  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = var.vcn_cidr
    source_type = "CIDR_BLOCK"
    description = "ICMP within VCN"

    icmp_options {
      type = 3
      code = 4
    }
  }

  # Egress: All traffic (for package updates, XATbackend upload)
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    description      = "Allow all outbound"
  }

  freeform_tags = var.common_tags
}

# Public Subnet
resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.perftest.id
  cidr_block                 = var.public_subnet_cidr
  display_name               = "${var.name_prefix}-subnet-public"
  dns_label                  = "public"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.public.id]

  freeform_tags = var.common_tags
}

# Private Subnet
resource "oci_core_subnet" "private" {
  compartment_id             = var.compartment_id
  vcn_id                     = oci_core_vcn.perftest.id
  cidr_block                 = var.private_subnet_cidr
  display_name               = "${var.name_prefix}-subnet-private"
  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.private.id
  security_list_ids          = [oci_core_security_list.private.id]

  freeform_tags = var.common_tags
}
