output "vpc_id" {
  description = "ID of the customer-managed VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "ID of the public subnet that hosts the NAT Gateway."
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "IDs of the two Databricks private subnets."
  value       = aws_subnet.private[*].id
}

output "private_subnet_availability_zones" {
  description = "Availability Zones used by the Databricks private subnets."
  value       = aws_subnet.private[*].availability_zone
}

output "security_group_id" {
  description = "ID of the Databricks workspace security group."
  value       = aws_security_group.workspace.id
}

output "nat_gateway_id" {
  description = "ID of the single zonal NAT Gateway."
  value       = aws_nat_gateway.this.id
}

output "nat_gateway_public_ip" {
  description = "Public IPv4 address used by the NAT Gateway."
  value       = aws_eip.nat.public_ip
}

output "private_route_table_id" {
  description = "ID of the shared private route table."
  value       = aws_route_table.private.id
}

output "s3_gateway_endpoint_id" {
  description = "ID of the optional S3 gateway endpoint."
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}
