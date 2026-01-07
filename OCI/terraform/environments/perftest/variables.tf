# Variables for PerfTest Environment

# OCI Provider Configuration
variable "tenancy_ocid" {
  description = "OCID of the tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API signing key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
}

variable "region" {
  description = "OCI region (e.g., us-ashburn-1, us-phoenix-1)"
  type        = string
}

# Network Configuration
variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.10.0/24"
}

variable "admin_cidr" {
  description = "CIDR for admin SSH access (recommend setting to your IP/32)"
  type        = string
  default     = "0.0.0.0/0"
}

# Compute Configuration
variable "instance_count" {
  description = "Number of performance test VMs to create"
  type        = number
  default     = 2
}

variable "instance_shape" {
  description = "Compute shape (VM.Standard.A1.Flex for ARM free tier, VM.Standard.E2.1.Micro for AMD)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs for A1.Flex instances (1-4 within free tier)"
  type        = number
  default     = 1
}

variable "instance_memory_gb" {
  description = "Memory in GB for A1.Flex instances (6GB per OCPU within free tier)"
  type        = number
  default     = 6
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB (up to 200GB total free tier)"
  type        = number
  default     = 50
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

# Tags
variable "common_tags" {
  description = "Common freeform tags for all resources"
  type        = map(string)
  default = {
    "ManagedBy"   = "Terraform"
    "Project"     = "PerfAnalysis"
    "Environment" = "PerfTest"
    "CostCenter"  = "FreeTier"
  }
}
