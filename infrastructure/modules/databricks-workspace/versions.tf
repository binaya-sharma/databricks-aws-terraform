terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      version               = ">= 1.137, < 2.0"
      configuration_aliases = [databricks.mws]
    }
  }
}
