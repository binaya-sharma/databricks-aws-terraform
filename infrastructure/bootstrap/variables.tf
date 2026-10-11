variable "aws_region" {
  description = "AWS region that stores Terraform state."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region name."
  }
}

variable "project_name" {
  description = "Short lowercase project name used in resource names and tags."
  type        = string
  default     = "databricks"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3 to 32 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Environment label for the shared state foundation."
  type        = string
  default     = "shared"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,14}[a-z0-9]$", var.environment))
    error_message = "environment must be 3 to 16 lowercase letters, numbers, or hyphens."
  }
}

variable "owner" {
  description = "Team or person responsible for the state foundation."
  type        = string

  validation {
    condition     = length(trimspace(var.owner)) > 0
    error_message = "owner must not be empty."
  }
}

variable "state_bucket_name" {
  description = "Optional globally unique S3 bucket name. A name is generated when null."
  type        = string
  default     = null

  validation {
    condition = var.state_bucket_name == null || can(regex(
      "^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$",
      var.state_bucket_name
    ))
    error_message = "state_bucket_name must be a valid 3 to 63 character S3 bucket name."
  }
}

variable "force_destroy_state_bucket" {
  description = "Allow deletion of all state object versions when retiring the lab."
  type        = bool
  default     = false
}

variable "environment_state_keys" {
  description = "S3 object key used by each environment Terraform state."
  type        = map(string)
  default = {
    dev  = "databricks/dev/terraform.tfstate"
    qa   = "databricks/qa/terraform.tfstate"
    prod = "databricks/prod/terraform.tfstate"
  }

  validation {
    condition = (
      toset(keys(var.environment_state_keys)) == toset(["dev", "qa", "prod"])
      && alltrue([for key in values(var.environment_state_keys) : length(trimspace(key)) > 0])
    )
    error_message = "environment_state_keys must contain non-empty dev, qa, and prod keys."
  }
}

variable "additional_tags" {
  description = "Extra tags added to bootstrap resources."
  type        = map(string)
  default     = {}
}
