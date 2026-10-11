variable "name_prefix" {
  description = "Prefix used for network resource names."
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
  description = "Two private subnet CIDRs used by Databricks Classic Compute."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly two private subnet CIDRs are required."
  }
}

variable "availability_zones" {
  description = "Two distinct Availability Zones for the private subnets."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 2 && length(toset(var.availability_zones)) == 2
    error_message = "Exactly two distinct Availability Zones are required."
  }
}

variable "enable_s3_gateway_endpoint" {
  description = "Create the no-hourly-charge S3 gateway endpoint."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all network resources."
  type        = map(string)
}
