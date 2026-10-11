output "vpc_id" {
  description = "ID of the customer-managed VPC."
  value       = module.networking.vpc_id
}

output "public_subnet_id" {
  description = "ID of the NAT Gateway public subnet."
  value       = module.networking.public_subnet_id
}

output "private_subnet_ids" {
  description = "IDs of the Databricks private subnets."
  value       = module.networking.private_subnet_ids
}

output "private_subnet_availability_zones" {
  description = "Availability Zones of the Databricks private subnets."
  value       = module.networking.private_subnet_availability_zones
}

output "security_group_id" {
  description = "ID of the Databricks workspace security group."
  value       = module.networking.security_group_id
}

output "nat_gateway_id" {
  description = "ID of the single NAT Gateway."
  value       = module.networking.nat_gateway_id
}

output "nat_gateway_public_ip" {
  description = "Public IP address used by the NAT Gateway."
  value       = module.networking.nat_gateway_public_ip
}

output "s3_gateway_endpoint_id" {
  description = "ID of the optional S3 gateway endpoint."
  value       = module.networking.s3_gateway_endpoint_id
}

output "cross_account_role_arn" {
  description = "ARN of the cross-account IAM role assumed by Databricks."
  value       = module.iam.cross_account_role_arn
}

output "cross_account_role_name" {
  description = "Name of the cross-account IAM role assumed by Databricks."
  value       = module.iam.cross_account_role_name
}

output "root_bucket_name" {
  description = "Name of the Databricks workspace root S3 bucket."
  value       = module.storage.bucket_name
}

output "credentials_id" {
  description = "Databricks credential configuration ID."
  value       = module.iam.credentials_id
}

output "storage_configuration_id" {
  description = "Databricks storage configuration ID."
  value       = module.storage.storage_configuration_id
}

output "network_id" {
  description = "Databricks network configuration ID."
  value       = module.databricks_workspace.network_id
}

output "network_status" {
  description = "Databricks network validation status."
  value       = module.databricks_workspace.network_status
}

output "workspace_id" {
  description = "Databricks workspace ID."
  value       = module.databricks_workspace.workspace_id
}

output "workspace_status" {
  description = "Databricks workspace status."
  value       = module.databricks_workspace.workspace_status
}

output "workspace_status_message" {
  description = "Databricks workspace status details."
  value       = module.databricks_workspace.workspace_status_message
}

output "workspace_url" {
  description = "Databricks workspace URL."
  value       = module.databricks_workspace.workspace_url
}
