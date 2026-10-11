# Project scratchpad

Working notes for resuming this project. Use the design, operations, and reference guides for durable instructions. Do not store credentials, secrets, or account-specific identifiers here.

Last updated: 2026-10-11

## Current state

- The `dev` environment is the only implemented environment. `qa` and `prod` are placeholders.
- The bootstrap S3 state bucket exists. Bootstrap state is local in `infrastructure/bootstrap/terraform.tfstate`; preserve it while the bucket is managed by Terraform.
- The development backend is initialized in S3. Its ignored `backend.hcl` points at the development state object.
- The VPC foundation is applied: VPC, three subnets, Internet Gateway, public and private route tables, route associations, and the public Internet Gateway route.
- NAT Gateway, Elastic IP, workspace security group, workspace root storage, cross-account IAM role, Databricks workspace, Unity Catalog resources, and compute remain uncreated.
- The AWS profile is stored in the devcontainer's persistent `.aws` volume. Verify the active account before any plan or apply.
- `tmp/` contains ignored local plans and the deferred development variables template. Regenerate plans after code or variable changes.

## Next step

Review and plan the remaining networking resources: Elastic IP, NAT Gateway, private default route, security group rules, and S3 Gateway Endpoint. Check the default network ACL and keep public IPv4 auto-assignment disabled. The full development root also includes IAM, storage, and Databricks resources, so review its complete plan before any full apply.

## Resume links

- [Project guide](README.md)
- [Networking design](design/networking.md)
- [VPC foundation](step-by-step/vpc-foundation.md)
- [NAT Gateway explanation](step-by-step/why-nat-gateway-for-databricks.md)
- [Deployment](operations/deployment.md)
- [Terraform state](reference/terraform-state.md)
