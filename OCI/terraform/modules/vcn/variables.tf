# Variables for VCN Module

variable "compartment_id" {
  description = "OCID of the compartment for network resources"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "perftest"
}

variable "vcn_cidr" {
  description = "CIDR block for the VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vcn_dns_label" {
  description = "DNS label for the VCN"
  type        = string
  default     = "perftest"
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
  description = "CIDR for admin SSH access (your IP or 0.0.0.0/0 for testing)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "common_tags" {
  description = "Common freeform tags to apply to all resources"
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
    "Project"   = "PerfAnalysis"
  }
}
