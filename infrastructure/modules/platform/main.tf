locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.additional_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Purpose     = "Learning"
    Owner       = var.owner
  })
}

locals {
  vpc_cidr_bounds = {
    start = sum([
      for index, octet in split(".", cidrhost(var.vpc_cidr, 0)) :
      tonumber(octet) * pow(256, 3 - index)
    ])
    end = sum([
      for index, octet in split(".", cidrhost(var.vpc_cidr, -1)) :
      tonumber(octet) * pow(256, 3 - index)
    ])
  }

  subnet_cidr_bounds = [
    for cidr in concat([var.public_subnet_cidr], var.private_subnet_cidrs) : {
      start = sum([
        for index, octet in split(".", cidrhost(cidr, 0)) :
        tonumber(octet) * pow(256, 3 - index)
      ])
      end = sum([
        for index, octet in split(".", cidrhost(cidr, -1)) :
        tonumber(octet) * pow(256, 3 - index)
      ])
    }
  ]
}

resource "terraform_data" "network_validation" {
  lifecycle {
    precondition {
      condition = (
        length(var.availability_zones) == 2
        && length(toset(var.availability_zones)) == 2
        && alltrue([for az in var.availability_zones : startswith(az, var.aws_region)])
      )
      error_message = "availability_zones must contain two distinct zones in aws_region."
    }

    precondition {
      condition = alltrue([
        for subnet in local.subnet_cidr_bounds :
        subnet.start >= local.vpc_cidr_bounds.start
        && subnet.end <= local.vpc_cidr_bounds.end
      ])
      error_message = "All subnet CIDRs must be contained by vpc_cidr."
    }

    precondition {
      condition     = length(toset(concat([var.public_subnet_cidr], var.private_subnet_cidrs))) == 3
      error_message = "The public and private subnet CIDRs must be unique."
    }

    precondition {
      condition = alltrue([
        for index, subnet in local.subnet_cidr_bounds : alltrue([
          for other_index, other_subnet in local.subnet_cidr_bounds :
          index >= other_index || subnet.end < other_subnet.start || other_subnet.end < subnet.start
        ])
      ])
      error_message = "The public and private subnet CIDRs must not overlap."
    }
  }
}

module "networking" {
  source = "../networking"

  name_prefix                = local.name_prefix
  vpc_cidr                   = var.vpc_cidr
  public_subnet_cidr         = var.public_subnet_cidr
  private_subnet_cidrs       = var.private_subnet_cidrs
  availability_zones         = var.availability_zones
  enable_s3_gateway_endpoint = var.enable_s3_gateway_endpoint
  tags                       = local.common_tags

  depends_on = [terraform_data.network_validation]
}

module "iam" {
  source = "../iam"

  providers = {
    aws            = aws
    databricks.mws = databricks.mws
  }

  name_prefix           = local.name_prefix
  databricks_account_id = var.databricks_account_id
  tags                  = local.common_tags
}

module "storage" {
  source = "../storage"

  providers = {
    aws            = aws
    databricks.mws = databricks.mws
  }

  name_prefix           = local.name_prefix
  databricks_account_id = var.databricks_account_id
  force_destroy         = var.force_destroy_root_bucket
  enable_versioning     = var.enable_root_bucket_versioning
  tags                  = local.common_tags
}

module "databricks_workspace" {
  source = "../databricks-workspace"

  providers = {
    databricks.mws = databricks.mws
  }

  databricks_account_id    = var.databricks_account_id
  aws_region               = var.aws_region
  workspace_name           = var.databricks_workspace_name
  name_prefix              = local.name_prefix
  vpc_id                   = module.networking.vpc_id
  private_subnet_ids       = module.networking.private_subnet_ids
  security_group_id        = module.networking.security_group_id
  credentials_id           = module.iam.credentials_id
  storage_configuration_id = module.storage.storage_configuration_id
  custom_tags              = local.common_tags
}
