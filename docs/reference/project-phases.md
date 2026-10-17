# Project phases

This file records what is complete and what remains. Terraform configuration in `infrastructure/environments/dev` is the source of truth for the active phase. The Databricks modules under `tobeimplement-temp` are retained for later work and are not called by the active root.

Last reviewed: 2026-10-12

## Phase 1: Terraform state bootstrap

**Status: Complete and retained**

- The S3 bucket for remote Terraform state has been created.
- Bootstrap state remains local in `infrastructure/bootstrap/terraform.tfstate`; preserve it while Terraform manages the bucket.
- The dev environment has an S3 backend configuration.

## Phase 2: AWS VPC foundation

**Status: Completed and currently destroyed**

- VPC with DNS support and DNS hostnames. The VPC has since been destroyed.
- Three subnets: one public and two private.
- Internet Gateway, public and private route tables, route associations, and the public Internet Gateway route.
- Public IPv4 auto-assignment is disabled.

## Phase 3: AWS networking completion

**Status: Completed, verified, and currently destroyed**

The active Terraform root now manages the complete planned networking layer:

- Elastic IP and public NAT Gateway.
- Private default route through the NAT Gateway.
- Workspace security group and its configured rules.
- S3 Gateway Endpoint.
- Default network ACL retained; public IPv4 auto-assignment remains disabled.

Terraform applied 13 resources with no changes to existing resources and no destroys. A follow-up plan reported no changes. AWS reported the NAT Gateway and S3 Gateway Endpoint as `available`. The dev networking destroy later removed 25 resources, including the VPC foundation, NAT Gateway, security group, and endpoint. The bootstrap state bucket remains intact.

Use [deployment](../operations/deployment.md), [cleanup](../operations/cleanup.md), and the [networking design](../design/networking.md) when recreating this phase.

## Phase 4: Databricks account integration and workspace

**Status: Not started**

Terraform modules for the following work are retained in `tobeimplement-temp/databricks/modules` and are not part of the active dev root:

- AWS cross-account IAM role and Databricks credential registration.
- Workspace root S3 bucket and Databricks storage registration.
- Databricks network registration and workspace creation.

Before starting, confirm Databricks account access, account ID, authentication, workspace eligibility, and required AWS permissions. Move the modules back into the active Terraform tree only when this phase is ready, then review provider wiring and the complete plan.

## Phase 5: Unity Catalog

**Status: Not started**

- Define the regional metastore and workspace assignment.
- Set up a dedicated managed-storage location and least-privilege AWS identity.
- Create storage credentials, approved external locations, catalogs, and schemas.
- Define ownership, group-based grants, and any required workspace bindings or data controls.
- Verify allowed and denied access, audit records, and lineage.

See the [Unity Catalog governance guide](../design/unity-catalog-governance.md) for the planned design and implementation checklist. These items are not deployed.

## Phase 6: Compute and validation

**Status: Not started**

- Add a small, controlled compute example only after workspace and catalog access work.
- Validate permissions, connectivity, and cleanup.
- Document observed costs and teardown results.

## Current scope

The active dev Terraform root should plan AWS networking only. It must not plan Databricks account resources, workspace root storage, clusters, SQL warehouses, jobs, or other compute. See the [scratchpad](../scratchpad.md) for the immediate resume point.
