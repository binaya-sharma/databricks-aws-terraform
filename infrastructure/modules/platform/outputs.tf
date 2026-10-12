output "vpc_id" {
  description = "ID of the VPC."
  value       = module.networking.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet reserved for NAT egress."
  value       = module.networking.public_subnet_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.networking.private_subnet_ids
}

output "private_subnet_availability_zones" {
  description = "Availability Zones of the private subnets."
  value       = module.networking.private_subnet_availability_zones
}

output "security_group_id" {
  description = "ID of the workspace security group."
  value       = module.networking.security_group_id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway."
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
