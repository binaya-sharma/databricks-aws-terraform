# Project scratchpad

Working notes for resuming this project. Use the design, operations, and reference guides for durable instructions. Do not store credentials, secrets, or account-specific identifiers here.

Last updated: 2026-10-12

## Current state

- The `dev` environment is the only implemented environment. `qa` and `prod` are placeholders.
- The bootstrap S3 state bucket exists. Bootstrap state is local in `infrastructure/bootstrap/terraform.tfstate`; preserve it while the bucket is managed by Terraform.
- The development backend is initialized in S3. Its ignored `backend.hcl` points at the development state object.
- All dev networking was applied and verified, then destroyed: VPC, subnets, gateways, route tables, security group, and S3 endpoint. The dev backend state is now empty.
- The active Terraform root still defines AWS networking only. Reapplying the dev configuration will recreate those resources.
- Unstarted Databricks IAM, root storage, and workspace modules are parked in `tobeimplement-temp/databricks/modules`; Unity Catalog and compute are not implemented.
- The AWS profile is stored in the devcontainer's persistent `.aws` volume. Verify the active account before any plan or apply.
- The tracked development variable template is `infrastructure/environments/dev/terraform.tfvars.example`; copy it to the ignored `terraform.tfvars` and replace placeholders before planning. Generate a fresh plan after configuration or variable changes.

## Next step

When resuming, reapply and verify AWS networking before beginning Databricks account integration. The IAM, storage, and workspace Terraform modules are parked in `tobeimplement-temp/databricks/modules`; review current Databricks requirements and authentication before reconnecting them. The active development root should continue to plan AWS networking only until that work is deliberately reintroduced.

## Resume links

- [Project guide](README.md)
- [Networking design](design/networking.md)
- [VPC foundation](step-by-step/vpc-foundation.md)
- [NAT Gateway explanation](step-by-step/why-nat-gateway-for-databricks.md)
- [Deployment](operations/deployment.md)
- [Terraform state](reference/terraform-state.md)
