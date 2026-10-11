data "aws_caller_identity" "current" {}

resource "random_id" "bucket_suffix" {
  byte_length = 4

  keepers = {
    project_name = var.project_name
    environment  = var.environment
  }
}

locals {
  generated_bucket_name = join("-", [
    var.project_name,
    var.environment,
    "tfstate",
    data.aws_caller_identity.current.account_id,
    random_id.bucket_suffix.hex,
  ])

  state_bucket_name = coalesce(var.state_bucket_name, local.generated_bucket_name)

  common_tags = merge(var.additional_tags, {
    Application = "databricks"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.owner
    Project     = var.project_name
  })
}

resource "aws_s3_bucket" "terraform_state" {
  bucket        = local.state_bucket_name
  force_destroy = var.force_destroy_state_bucket
}

resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
