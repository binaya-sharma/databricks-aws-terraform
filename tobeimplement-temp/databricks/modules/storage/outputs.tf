output "bucket_name" {
  description = "Name of the private Databricks workspace root bucket."
  value       = aws_s3_bucket.root.bucket
}

output "bucket_arn" {
  description = "ARN of the Databricks workspace root bucket."
  value       = aws_s3_bucket.root.arn
}

output "storage_configuration_id" {
  description = "Databricks account storage configuration ID."
  value       = databricks_mws_storage_configurations.workspace.storage_configuration_id
}
