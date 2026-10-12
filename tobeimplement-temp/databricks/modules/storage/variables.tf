variable "name_prefix" {
  description = "Prefix used for S3 and Databricks storage names."
  type        = string
}

variable "databricks_account_id" {
  description = "Databricks account ID used to restrict the generated bucket policy."
  type        = string
}

variable "force_destroy" {
  description = "Allow Terraform to delete all root-bucket objects during lab cleanup."
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable root-bucket object versioning. Disabled by default for the temporary lab."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to S3 resources."
  type        = map(string)
}
