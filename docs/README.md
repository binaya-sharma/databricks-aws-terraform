# Project guide

This is the documentation index and the stable starting point for understanding the repository. Use the linked references for detailed design and operating steps.

## Project status

The repository defines a learning lab for a Databricks Classic workspace in AWS. The `dev` environment is implemented. The `qa` and `prod` directories are placeholders and do not contain deployable Terraform. The bootstrap state bucket and first phase of the development VPC network have been applied. Later networking and Databricks resources remain uncreated.

The infrastructure is designed to configure the customer VPC, Databricks account resources, and workspace without creating compute. Terraform code and instructions do not imply that later stages have been applied. Bootstrap and development deployment are separate steps.

## Documentation map

### Design

- [Architecture](design/architecture.md) explains system components, ownership, and traffic flow.
- [Networking concepts](design/networking.md) documents CIDRs, routing, and security group rules.

### Step by step

- [VPC foundation](step-by-step/vpc-foundation.md) walks through VPC creation, CIDR planning, subnets, Internet Gateway routing, and public IPv4 assignment.

### Operations

- [Development environment](operations/development-environment.md) covers the devcontainer and local commands.
- [Deployment](operations/deployment.md) gives the preparation, validation, and deployment sequence.
- [Cost estimation](operations/cost-estimation.md) records cost assumptions and budget alerts.
- [Cleanup](operations/cleanup.md) describes teardown and residual checks.

### Reference

- [Terraform state](reference/terraform-state.md) explains the S3 bootstrap bucket, backend configuration, and state handling.

### Working notes

- [Project scratchpad](scratchpad.md) preserves current setup and the next resume point.

The [repository README](../README.md) provides a short project overview and repository map.

## Infrastructure lifecycle

1. Prepare local credentials, variables, and AWS budget alerts.
2. Validate the Terraform configuration without making cloud changes.
3. Review and approve the bootstrap plan. Bootstrap creates the S3 state bucket.
4. Configure the development backend and review the development plan.
5. Review and approve development deployment separately.
6. Verify the workspace without launching compute.
7. Destroy development resources, check for leftovers, then retire bootstrap state only if the lab is ending.

The detailed commands and checkpoints are in [deployment](operations/deployment.md), [cleanup](operations/cleanup.md), and [Terraform state](reference/terraform-state.md).

## Project rules

- Keep bootstrap state separate from environment state.
- Keep provider lock files under version control.
- Do not store AWS keys, Databricks secrets, or tokens in Terraform files.
- Use provider generated Databricks IAM and bucket policies.
- Do not add clusters, jobs, SQL warehouses, or EC2 instances to this lab.
- Do not add paid interface endpoints or PrivateLink without revisiting scope and cost.
- Preserve the single NAT Gateway design unless cost and availability assumptions change.
- Use resource references for dependency ordering. Do not add arbitrary delays.
- Do not add public ingress to the workspace security group.
- Tag resources with project, environment, owner, purpose, and management tool where supported.
- Review every plan and confirm the target account and region before applying.
- Require explicit approval before applying or destroying infrastructure.

## Documentation conventions

- Use plain English, short sections, and numbered operational procedures.
- Define abbreviations when they first appear.
- Use placeholders for account IDs, profile names, and secrets.
- Record cost assumptions and the date they were checked.
- Link to official references for external requirements.
- Do not use the em dash character.
- Avoid describing the learning design as production ready.
- Update all affected guides when infrastructure behavior changes.

## Planned learning sequence

1. Validate prerequisites and the development design.
2. Create and verify the development environment, then prove cleanup.
3. Decide what QA needs before implementing it. Do not copy development configuration blindly.
4. Design production only after account separation, availability, security, and operational requirements are documented.

## Ownership boundaries

| Layer | Responsibility |
| --- | --- |
| Bootstrap | S3 bucket that stores environment Terraform state. |
| Networking module | VPC, subnets, routes, NAT, security group, and S3 gateway endpoint. |
| IAM module | Cross account role and Databricks credential configuration. |
| Storage module | Workspace root bucket and Databricks storage configuration. |
| Databricks workspace module | Databricks network and workspace account resources. |
| Platform module | Composition of the shared modules for an environment. |
| Operator | Credentials, account selection, plan review, approvals, verification, and cleanup. |

Do not manage one resource both manually and with Terraform. If an emergency manual change is made, reconcile it into code or import it before continuing.

## Official references

- [Databricks customer managed VPC requirements](https://docs.databricks.com/aws/en/security/network/classic/customer-managed-vpc)
- [Databricks manual workspace creation](https://docs.databricks.com/aws/en/admin/workspace/create-uc-workspace)
- [Databricks OAuth machine to machine authentication](https://docs.databricks.com/aws/en/dev-tools/auth/oauth-m2m)
- [Databricks Terraform AWS workspace guide](https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/aws-workspace)
- [AWS subnet sizing](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html)
- [Amazon VPC pricing](https://aws.amazon.com/vpc/pricing/)
- [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)
