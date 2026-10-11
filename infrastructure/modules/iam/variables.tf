variable "name_prefix" {
  description = "Prefix used for IAM and Databricks credential names."
  type        = string
}

variable "databricks_account_id" {
  description = "Databricks account ID used as the external ID."
  type        = string
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
}
