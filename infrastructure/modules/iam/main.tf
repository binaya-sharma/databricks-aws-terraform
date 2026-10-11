data "databricks_aws_assume_role_policy" "workspace" {
  provider    = databricks.mws
  external_id = var.databricks_account_id
}

data "databricks_aws_crossaccount_policy" "workspace" {
  provider    = databricks.mws
  policy_type = "customer"
}

resource "aws_iam_role" "cross_account" {
  name               = "${var.name_prefix}-cross-account"
  description        = "Allows Databricks to manage Classic Compute resources in the customer VPC"
  assume_role_policy = data.databricks_aws_assume_role_policy.workspace.json

  tags = var.tags
}

resource "aws_iam_role_policy" "cross_account" {
  name   = "${var.name_prefix}-cross-account"
  role   = aws_iam_role.cross_account.id
  policy = data.databricks_aws_crossaccount_policy.workspace.json
}

resource "databricks_mws_credentials" "workspace" {
  provider = databricks.mws

  account_id       = var.databricks_account_id
  credentials_name = "${var.name_prefix}-credentials"
  role_arn         = aws_iam_role.cross_account.arn

  depends_on = [aws_iam_role_policy.cross_account]
}
