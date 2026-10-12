# Project phases

This file records what is complete and what remains. Terraform configuration in `infrastructure/environments/dev` is the source of truth for the active phase. The Databricks modules under `tobeimplement-temp` are retained for later work and are not called by the active root.

Last reviewed: 2026-10-12

## Phase 1: Terraform state bootstrap

**Status: Complete**

- The S3 bucket for remote Terraform state has been created.
- Bootstrap state remains local in `infrastructure/bootstrap/terraform.tfstate`; preserve it while Terraform manages the bucket.
- The dev environment has an S3 backend configuration.

## Phase 2: AWS VPC foundation

**Status: Complete**

- VPC with DNS support and DNS hostnames.
- Three subnets: one public and two private.
- Internet Gateway, public and private route tables, route associations, and the public Internet Gateway route.
- Public IPv4 auto-assignment is disabled.

## Phase 3: Remaining AWS networking

**Status: Not complete**

The active Terraform root contains the planned networking configuration. Review the full plan and costs before applying the remaining resources.

- Elastic IP and NAT Gateway.
- Private route to the NAT Gateway.
- Workspace security group rules.
- S3 Gateway Endpoint.
- Review the default network ACL and verify subnet settings.

Use [deployment](../operations/deployment.md), [cleanup](../operations/cleanup.md), and the [networking design](../design/networking.md) while completing this phase.

## Phase 4: Databricks account integration and workspace

**Status: Not started**

Terraform modules for the following work are retained in `tobeimplement-temp/databricks/modules` and are not part of the active dev root:

- AWS cross-account IAM role and Databricks credential registration.
- Workspace root S3 bucket and Databricks storage registration.
- Databricks network registration and workspace creation.

Before starting, confirm Databricks account access, account ID, authentication, workspace eligibility, and required AWS permissions. Move the modules back into the active Terraform tree only when this phase is ready, then review provider wiring and the complete plan.

## Phase 5: Unity Catalog

**Status: Not started**

- Define the Unity Catalog metastore and region strategy.
- Create storage credentials and external locations with least privilege.
- Configure workspace assignment and access grants.

## Phase 6: Compute and validation

**Status: Not started**

- Add a small, controlled compute example only after workspace and catalog access work.
- Validate permissions, connectivity, and cleanup.
- Document observed costs and teardown results.

## Current scope

The active dev Terraform root should plan AWS networking only. It must not plan Databricks account resources, workspace storage, clusters, SQL warehouses, jobs, or other compute. See the [scratchpad](../scratchpad.md) for the immediate resume point.
