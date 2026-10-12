output "network_id" {
  description = "Databricks account network configuration ID."
  value       = databricks_mws_networks.workspace.network_id
}

output "network_status" {
  description = "Validation status of the registered VPC network."
  value       = databricks_mws_networks.workspace.vpc_status
}

output "workspace_id" {
  description = "Databricks workspace ID."
  value       = databricks_mws_workspaces.workspace.workspace_id
}

output "workspace_status" {
  description = "Current Databricks workspace status."
  value       = databricks_mws_workspaces.workspace.workspace_status
}

output "workspace_status_message" {
  description = "Databricks workspace status details."
  value       = databricks_mws_workspaces.workspace.workspace_status_message
}

output "workspace_url" {
  description = "URL of the Databricks workspace."
  value       = databricks_mws_workspaces.workspace.workspace_url
}
