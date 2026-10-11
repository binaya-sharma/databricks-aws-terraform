resource "aws_s3_bucket" "root" {
  bucket_prefix = "${var.name_prefix}-root-"
  force_destroy = var.force_destroy

  tags = merge(var.tags, { Name = "${var.name_prefix}-root" })
}

resource "aws_s3_bucket_ownership_controls" "root" {
  bucket = aws_s3_bucket.root.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "root" {
  bucket = aws_s3_bucket.root.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "root" {
  bucket = aws_s3_bucket.root.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "root" {
  count = var.enable_versioning ? 1 : 0

  bucket = aws_s3_bucket.root.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "databricks_aws_bucket_policy" "root" {
  provider = databricks.mws

  bucket                   = aws_s3_bucket.root.bucket
  databricks_e2_account_id = var.databricks_account_id
}

resource "aws_s3_bucket_policy" "root" {
  bucket = aws_s3_bucket.root.id
  policy = data.databricks_aws_bucket_policy.root.json

  depends_on = [aws_s3_bucket_public_access_block.root]
}

resource "databricks_mws_storage_configurations" "workspace" {
  provider = databricks.mws

  account_id                 = var.databricks_account_id
  storage_configuration_name = "${var.name_prefix}-storage"
  bucket_name                = aws_s3_bucket.root.bucket

  depends_on = [aws_s3_bucket_policy.root]
}
