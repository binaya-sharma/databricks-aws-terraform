output "state_bucket_name" {
  description = "Name of the S3 bucket that stores Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_region" {
  description = "AWS region of the Terraform state bucket."
  value       = var.aws_region
}

output "backend_hcl_by_environment" {
  description = "Backend configuration for each environment root."
  value = {
    for environment, state_key in var.environment_state_keys : environment => <<-EOT
      bucket       = "${aws_s3_bucket.terraform_state.id}"
      key          = "${state_key}"
      region       = "${var.aws_region}"
      encrypt      = true
      use_lockfile = true
    EOT
  }
}
