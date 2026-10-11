# Project scratchpad

This file preserves working context between sessions. The design and operating guides remain the long term reference. Do not put credentials, access keys, secrets, or account-specific identifiers here.

Last updated: 2026-10-11

## Current project state

- The `dev` environment is the only implemented environment. `qa` and `prod` remain placeholders.
- AWS CLI profile `databricks-lab-admin` is configured in the devcontainer's persistent `.aws` volume for `us-east-1`.
- The AWS identity check succeeded. Read the account identity again with `aws sts get-caller-identity --profile databricks-lab-admin` when resuming.
- The Terraform bootstrap state bucket was created in `us-east-1`. Get its exact name with `terraform -chdir=infrastructure/bootstrap output -raw state_bucket_name`.
- The bucket has versioning, AES256 server-side encryption, bucket owner enforced ownership, and all S3 public access blocks enabled. `force_destroy_state_bucket` is false.
- Bootstrap Terraform state is local under `infrastructure/bootstrap`. Keep that state file safe. It tracks the state bucket itself.
- `infrastructure/environments/dev/backend.hcl` was generated from the bootstrap output and is ignored by Git. It points the development state to `databricks/dev/terraform.tfstate` in the state bucket.
- The development backend is initialized against S3. No development VPC, Databricks workspace, NAT Gateway, or compute has been created.
- Generated Terraform plans and the deferred development variables template are in the local ignored `tmp` directory. Plans are previews and must be regenerated after configuration or variable changes.

## Networking reference

The first networking learning phase is documented in [VPC foundation walkthrough](step-by-step/vpc-foundation.md). The intended address plan is:

| Component | CIDR | Notes |
| --- | --- | --- |
| VPC | `10.20.0.0/16` | Check for overlap with connected networks before deployment. |
| Public subnet | `10.20.1.0/24` | Future NAT Gateway subnet. |
| Private subnet 1 | `10.20.11.0/24` | Databricks subnet in one Availability Zone. |
| Private subnet 2 | `10.20.12.0/24` | Databricks subnet in a different Availability Zone. |

The guide explains CIDR sizing, subnet creation, Internet Gateway attachment, route table associations, and how routes determine whether a subnet is public or private. It also explains the public IPv4 auto-assignment option.

The current Terraform code sets `map_public_ip_on_launch = false` for all three subnets. Keep it disabled unless the project design and Terraform are deliberately updated together. Use a separate temporary VPC for console practice. Do not create the Terraform-managed VPC manually.

## Resume here

1. Review the address plan and confirm `10.20.0.0/16` does not overlap any network this project needs to reach.
2. Choose two distinct available Availability Zones in `us-east-1`. Availability Zone letters can map differently across AWS accounts.
3. Confirm whether the next deployment is VPC foundation only or the full development platform. The development root composes networking, IAM, storage, and Databricks workspace resources. A full apply will not be VPC-only.
4. For VPC foundation only, inspect a targeted plan and confirm that the intended resource addresses are selected. Terraform targeting is a limited workflow and should be followed by a full plan review before relying on the configuration as fully applied.
5. Review the later networking phase: Elastic IP, NAT Gateway, private route behavior, security group rules, and default network ACL behavior in `infrastructure/modules/networking/main.tf`.
6. Review the public IPv4 auto-assignment choice. If it changes, update Terraform and documentation before deployment.
7. Review any plan before applying it. NAT Gateway and public IPv4 resources have ongoing charges.

## Current documentation

- [Project guide](README.md)
- [Networking concepts](design/networking.md)
- [VPC foundation walkthrough](step-by-step/vpc-foundation.md)
- [Terraform state and bootstrap](reference/terraform-state.md)
- [Deployment](operations/deployment.md)
- [Cleanup](operations/cleanup.md)

## Reminder

No networking walkthrough step has been applied in AWS. The new guide is instructional only. The existing Terraform network module defines the full planned stack, including an Elastic IP, one NAT Gateway, route tables, security group rules, and the S3 gateway endpoint.
