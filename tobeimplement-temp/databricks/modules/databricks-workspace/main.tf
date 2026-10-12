resource "databricks_mws_networks" "workspace" {
  provider = databricks.mws

  account_id         = var.databricks_account_id
  network_name       = "${var.name_prefix}-network"
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.security_group_id]
}

resource "databricks_mws_workspaces" "workspace" {
  provider = databricks.mws

  account_id     = var.databricks_account_id
  aws_region     = var.aws_region
  workspace_name = var.workspace_name

  credentials_id           = var.credentials_id
  storage_configuration_id = var.storage_configuration_id
  network_id               = databricks_mws_networks.workspace.network_id
  custom_tags              = var.custom_tags
}
