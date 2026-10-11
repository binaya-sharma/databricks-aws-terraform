variable "aws_region" {
  description = "AWS region for all environment resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be dev, qa, or prod."
  }
}

variable "project_name" {
  description = "Lowercase project name used in resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3 to 32 lowercase letters, numbers, or hyphens."
  }
}

variable "owner" {
  description = "Person or team responsible for the resources."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the customer-managed VPC."
  type        = string
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR for the NAT Gateway public subnet."
  type        = string
}

variable "private_subnet_cidrs" {
  description = "Two Databricks private subnet CIDRs. Each prefix must be between /17 and /26."
  type        = list(string)

  validation {
    condition = (
      length(var.private_subnet_cidrs) == 2
      && alltrue([for cidr in var.private_subnet_cidrs : can(regex("/(1[7-9]|2[0-6])$", cidr))])
    )
    error_message = "Provide exactly two private subnet CIDRs with prefixes from /17 through /26."
  }
}

variable "availability_zones" {
  description = "Two distinct Availability Zones in aws_region."
  type        = list(string)
}

variable "databricks_account_id" {
  description = "Databricks account ID from the account console."
  type        = string
}

variable "databricks_workspace_name" {
  description = "Name displayed for the Databricks workspace."
  type        = string
}

variable "enable_s3_gateway_endpoint" {
  description = "Create the free S3 gateway endpoint on the private route table."
  type        = bool
  default     = true
}

variable "force_destroy_root_bucket" {
  description = "Allow Terraform to empty the disposable workspace root bucket during destroy."
  type        = bool
  default     = true
}

variable "enable_root_bucket_versioning" {
  description = "Enable object versioning on the workspace root bucket."
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Extra tags applied to supported AWS resources."
  type        = map(string)
  default     = {}
}
