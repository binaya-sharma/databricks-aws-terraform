variable "aws_region" {
  description = "AWS region for the environment."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional local AWS CLI profile. Leave null to use the default credential chain."
  type        = string
  default     = null
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Lowercase project name used in resource names."
  type        = string
  default     = "databricks-aws-terraform"
}

variable "owner" {
  description = "Person or team responsible for the resources."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the VPC."
  type        = string
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR for the NAT Gateway public subnet."
  type        = string
}

variable "private_subnet_cidrs" {
  description = "Two private subnet CIDRs for the development VPC."
  type        = list(string)
}

variable "availability_zones" {
  description = "Two distinct Availability Zones."
  type        = list(string)
}

variable "enable_s3_gateway_endpoint" {
  description = "Create the no-hourly-charge S3 gateway endpoint."
  type        = bool
  default     = true
}

variable "additional_tags" {
  description = "Extra tags applied to supported AWS resources."
  type        = map(string)
  default     = {}
}
