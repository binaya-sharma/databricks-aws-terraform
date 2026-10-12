# Databricks on AWS with Terraform

A long term learning reference for provisioning AWS networking as a foundation for a future Databricks Classic workspace. The active Terraform configuration currently manages AWS networking only.

## Start here

1. Read the [project guide](docs/README.md) for repository status and documentation map.
2. Review the [architecture](docs/design/architecture.md) and [network design](docs/design/networking.md).
3. Check prerequisites, authentication, and the cost estimate in the [deployment guide](docs/operations/deployment.md) and [cost guide](docs/operations/cost-estimation.md).
4. Follow the [cleanup guide](docs/operations/cleanup.md) before creating resources so the teardown path is understood.

## Current state

Only `dev` has deployable environment configuration. `qa` and `prod` are placeholders. The bootstrap S3 bucket and development VPC foundation have been created. The active dev root contains AWS networking only. Unstarted Databricks IAM, storage, and workspace modules are retained under `tobeimplement-temp/databricks/modules` for the later phase. See the [project phase tracker](docs/reference/project-phases.md) for status and next steps.

The development design includes one NAT Gateway and one public IPv4 address. Both incur charges while allocated, even when no compute is running. Review current prices and the plan before any apply.

## Repository map

| Path | Responsibility |
| --- | --- |
| `infrastructure/bootstrap` | Creates the S3 bucket used for remote Terraform state. |
| `infrastructure/environments/dev` | Development root module and remote backend configuration point. |
| `infrastructure/modules/platform` | Composes the active AWS networking module. |
| `infrastructure/modules/networking` | VPC, subnets, routes, NAT Gateway, security group, and S3 endpoint. |
| `tobeimplement-temp/databricks/modules` | Unstarted Databricks IAM, storage, and workspace Terraform modules, retained for the later phase. |
| `docs` | Project guide and operating references. |
| `diagrams` | Standalone architecture diagram. |
| `.devcontainer` | Reproducible local development environment. |
| `scripts` | Read-only verification and cleanup checks. |

## Operating boundary

Review the complete plan and confirm the AWS account, region, resources, and expected cost before any apply. Applying or destroying infrastructure requires explicit approval. See [deployment](docs/operations/deployment.md) and [cleanup](docs/operations/cleanup.md).
