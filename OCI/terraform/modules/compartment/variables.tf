# Variables for Compartment Module

variable "parent_compartment_id" {
  description = "OCID of the parent compartment (usually tenancy OCID)"
  type        = string
}

variable "parent_compartment_name" {
  description = "Name for the parent PerfAnalysis compartment"
  type        = string
  default     = "PerfAnalysis"
}

variable "environment" {
  description = "Environment name (e.g., PerfTest, Dev, Prod)"
  type        = string
  default     = "PerfTest"
}

variable "enable_delete" {
  description = "Allow compartments to be deleted (set false for production)"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common freeform tags to apply to all compartments"
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
    "Project"   = "PerfAnalysis"
  }
}
