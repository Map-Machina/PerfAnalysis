# OCI Compute Module
# Creates Always Free tier compute instances for performance testing

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0.0"
    }
  }
}

# Get latest Oracle Linux 8 image for ARM (Ampere A1)
data "oci_core_images" "oracle_linux_arm" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = ["^Oracle-Linux-8.*-aarch64-.*$"]
    regex  = true
  }
}

# Get latest Oracle Linux 8 image for AMD (x86_64)
data "oci_core_images" "oracle_linux_amd" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = "VM.Standard.E5.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = ["^Oracle-Linux-8.*-20.*$"]
    regex  = true
  }
}

# Availability Domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_id
}

# Cloud-init script
locals {
  cloud_init = var.cloud_init_script != "" ? var.cloud_init_script : templatefile("${path.module}/cloud-init.yaml", {
    go_version       = var.go_version
    perfcollector_repo = var.perfcollector_repo
  })

  # Select image based on shape
  image_id = var.instance_shape == "VM.Standard.A1.Flex" ? data.oci_core_images.oracle_linux_arm.images[0].id : data.oci_core_images.oracle_linux_amd.images[0].id
}

# Performance Test VM Instances
resource "oci_core_instance" "perftest" {
  count = var.instance_count

  compartment_id      = var.compartment_id
  # Use AD-2 (index 1) for all instances as AD-1 has capacity issues with free tier
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[min(1, length(data.oci_identity_availability_domains.ads.availability_domains) - 1)].name
  shape               = var.instance_shape
  display_name        = "${var.name_prefix}-vm-${format("%02d", count.index + 1)}"

  # Flex shape configuration (for A1.Flex and E5.Flex)
  dynamic "shape_config" {
    for_each = can(regex("Flex$", var.instance_shape)) ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_memory_gb
    }
  }

  source_details {
    source_type             = "image"
    source_id               = local.image_id
    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }

  create_vnic_details {
    subnet_id                 = var.subnet_id
    display_name              = "${var.name_prefix}-vnic-${format("%02d", count.index + 1)}"
    assign_public_ip          = var.assign_public_ip
    assign_private_dns_record = true
    hostname_label            = "${var.name_prefix}vm${format("%02d", count.index + 1)}"
    nsg_ids                   = var.nsg_ids
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(local.cloud_init)
  }

  freeform_tags = merge(var.common_tags, {
    "Name"     = "${var.name_prefix}-vm-${format("%02d", count.index + 1)}"
    "Index"    = tostring(count.index + 1)
    "Purpose"  = "Performance Testing"
  })

  # Prevent accidental destruction
  lifecycle {
    prevent_destroy = false
  }
}
