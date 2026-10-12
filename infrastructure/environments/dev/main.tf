terraform {
  required_version = ">= 1.10, < 2.0"

  # Bucket and key settings are supplied by backend.hcl during terraform init.
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
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

module "platform" {
  source = "../../modules/platform"

  aws_region                 = var.aws_region
  environment                = var.environment
  project_name               = var.project_name
  owner                      = var.owner
  vpc_cidr                   = var.vpc_cidr
  public_subnet_cidr         = var.public_subnet_cidr
  private_subnet_cidrs       = var.private_subnet_cidrs
  availability_zones         = var.availability_zones
  enable_s3_gateway_endpoint = var.enable_s3_gateway_endpoint
  additional_tags            = var.additional_tags
}

output "deployment_summary" {
  description = "Non-sensitive identifiers used for verification and cleanup."
  value = {
    project_name           = var.project_name
    environment            = var.environment
    aws_region             = var.aws_region
    vpc_id                 = module.platform.vpc_id
    public_subnet_id       = module.platform.public_subnet_id
    private_subnet_ids     = module.platform.private_subnet_ids
    private_subnet_azs     = module.platform.private_subnet_availability_zones
    security_group_id      = module.platform.security_group_id
    nat_gateway_id         = module.platform.nat_gateway_id
    nat_gateway_public_ip  = module.platform.nat_gateway_public_ip
    s3_gateway_endpoint_id = module.platform.s3_gateway_endpoint_id
  }
}
