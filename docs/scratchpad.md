# Project scratchpad

Working notes for resuming this project. Use the design, operations, and reference guides for durable instructions. Do not store credentials, secrets, or account-specific identifiers here.

Last updated: 2026-10-11

## Current state

- The `dev` environment is the only implemented environment. `qa` and `prod` are placeholders.
- The bootstrap S3 state bucket exists. Bootstrap state is local in `infrastructure/bootstrap/terraform.tfstate`; preserve it while the bucket is managed by Terraform.
- The development backend is initialized in S3. Its ignored `backend.hcl` points at the development state object.
- The VPC foundation is applied: VPC, three subnets, Internet Gateway, public and private route tables, route associations, and the public Internet Gateway route.
- The active Terraform root manages AWS networking only. NAT Gateway, Elastic IP, security group, and S3 Gateway Endpoint are the next networking stage.
- Unstarted Databricks IAM, root storage, and workspace modules are parked in `tobeimplement-temp/databricks/modules`; Unity Catalog and compute are not implemented.
- The AWS profile is stored in the devcontainer's persistent `.aws` volume. Verify the active account before any plan or apply.
- The tracked development variable template is `infrastructure/environments/dev/terraform.tfvars.example`; copy it to the ignored `terraform.tfvars` and replace placeholders before planning. Generate a fresh plan after configuration or variable changes.

## Next step

Review and plan the remaining networking resources: Elastic IP, NAT Gateway, private default route, security group rules, and S3 Gateway Endpoint. Check the default network ACL and keep public IPv4 auto-assignment disabled. The active development root should plan AWS networking only.

## Resume links

- [Project guide](README.md)
- [Networking design](design/networking.md)
- [VPC foundation](step-by-step/vpc-foundation.md)
- [NAT Gateway explanation](step-by-step/why-nat-gateway-for-databricks.md)
- [Deployment](operations/deployment.md)
- [Terraform state](reference/terraform-state.md)
