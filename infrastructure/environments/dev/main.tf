terraform {
  required_version = ">= 1.10, < 2.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.137, < 2.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "Learning"
      Owner       = var.owner
    }
  }
}

provider "databricks" {
  alias      = "mws"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
}

module "platform" {
  source = "../../modules/platform"

  providers = {
    aws            = aws
    databricks.mws = databricks.mws
  }

  aws_region                    = var.aws_region
  environment                   = var.environment
  project_name                  = var.project_name
  owner                         = var.owner
  vpc_cidr                      = var.vpc_cidr
  public_subnet_cidr            = var.public_subnet_cidr
  private_subnet_cidrs          = var.private_subnet_cidrs
  availability_zones            = var.availability_zones
  databricks_account_id         = var.databricks_account_id
  databricks_workspace_name     = var.databricks_workspace_name
  enable_s3_gateway_endpoint    = var.enable_s3_gateway_endpoint
  force_destroy_root_bucket     = var.force_destroy_root_bucket
  enable_root_bucket_versioning = var.enable_root_bucket_versioning
  additional_tags               = var.additional_tags
}

output "deployment_summary" {
  description = "Non-sensitive identifiers used for verification and cleanup."
  value = {
    project_name             = var.project_name
    environment              = var.environment
    aws_region               = var.aws_region
    vpc_id                   = module.platform.vpc_id
    public_subnet_id         = module.platform.public_subnet_id
    private_subnet_ids       = module.platform.private_subnet_ids
    private_subnet_azs       = module.platform.private_subnet_availability_zones
    security_group_id        = module.platform.security_group_id
    nat_gateway_id           = module.platform.nat_gateway_id
    nat_gateway_public_ip    = module.platform.nat_gateway_public_ip
    s3_gateway_endpoint_id   = module.platform.s3_gateway_endpoint_id
    cross_account_role_name  = module.platform.cross_account_role_name
    root_bucket_name         = module.platform.root_bucket_name
    credentials_id           = module.platform.credentials_id
    storage_configuration_id = module.platform.storage_configuration_id
    network_id               = module.platform.network_id
    network_status           = module.platform.network_status
    workspace_id             = module.platform.workspace_id
    workspace_status         = module.platform.workspace_status
    workspace_status_message = module.platform.workspace_status_message
    workspace_url            = module.platform.workspace_url
  }
}

output "workspace_url" {
  description = "Databricks workspace URL."
  value       = module.platform.workspace_url
}

output "workspace_status" {
  description = "Databricks workspace status."
  value       = module.platform.workspace_status
}
