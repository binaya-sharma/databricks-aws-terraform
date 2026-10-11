variable "databricks_account_id" {
  description = "Databricks account ID."
  type        = string
}

variable "aws_region" {
  description = "AWS region for the Databricks workspace."
  type        = string
}

variable "workspace_name" {
  description = "Name displayed for the Databricks workspace."
  type        = string
}

variable "name_prefix" {
  description = "Prefix used for Databricks account configuration names."
  type        = string
}

variable "vpc_id" {
  description = "Customer-managed VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "Two private subnet IDs in distinct Availability Zones."
  type        = list(string)
}

variable "security_group_id" {
  description = "Databricks workspace security group ID."
  type        = string
}

variable "credentials_id" {
  description = "Databricks credential configuration ID."
  type        = string
}

variable "storage_configuration_id" {
  description = "Databricks storage configuration ID."
  type        = string
}

variable "custom_tags" {
  description = "Tags Databricks applies to future workspace compute resources."
  type        = map(string)
}
