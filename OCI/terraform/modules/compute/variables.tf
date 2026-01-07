# Variables for Compute Module

variable "compartment_id" {
  description = "OCID of the compartment for compute resources"
  type        = string
}

variable "tenancy_id" {
  description = "OCID of the tenancy (for availability domains)"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet to place instances in"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "perftest"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
}

variable "instance_shape" {
  description = "Compute instance shape (VM.Standard.A1.Flex for ARM, VM.Standard.E2.1.Micro for AMD)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for flex shapes"
  type        = number
  default     = 1
}

variable "instance_memory_gb" {
  description = "Memory in GB for flex shapes"
  type        = number
  default     = 6
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB (50 GB is free tier)"
  type        = number
  default     = 50
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP (false for private subnet)"
  type        = bool
  default     = false
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "nsg_ids" {
  description = "List of Network Security Group OCIDs to attach"
  type        = list(string)
  default     = []
}

variable "cloud_init_script" {
  description = "Custom cloud-init script (leave empty to use default)"
  type        = string
  default     = ""
}

variable "go_version" {
  description = "Go version to install"
  type        = string
  default     = "1.21.6"
}

variable "perfcollector_repo" {
  description = "Git repository URL for perfcollector2"
  type        = string
  default     = "https://github.com/businessperformancetuning/perfcollector2.git"
}

variable "common_tags" {
  description = "Common freeform tags to apply to all resources"
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
    "Project"   = "PerfAnalysis"
  }
}
