output "cross_account_role_arn" {
  description = "ARN of the IAM role assumed by Databricks."
  value       = aws_iam_role.cross_account.arn
}

output "cross_account_role_name" {
  description = "Name of the IAM role assumed by Databricks."
  value       = aws_iam_role.cross_account.name
}

output "credentials_id" {
  description = "Databricks account credential configuration ID."
  value       = databricks_mws_credentials.workspace.credentials_id
}
