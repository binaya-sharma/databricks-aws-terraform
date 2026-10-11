# Databricks on AWS with Terraform

A long term learning reference for provisioning a Databricks Classic workspace in a customer managed Amazon VPC. Terraform configures the AWS and Databricks account resources. The project does not create clusters or other compute.

## Start here

1. Read the [project guide](docs/README.md) for repository status and documentation map.
2. Review the [architecture](docs/design/architecture.md) and [network design](docs/design/networking.md).
3. Check prerequisites, authentication, and the cost estimate in the [deployment guide](docs/operations/deployment.md) and [cost guide](docs/operations/cost-estimation.md).
4. Follow the [cleanup guide](docs/operations/cleanup.md) before creating resources so the teardown path is understood.

## Current state

Only `dev` has deployable environment configuration. `qa` and `prod` are placeholders. The bootstrap S3 bucket and the development VPC foundation have been created. The foundation includes the VPC, three subnets, Internet Gateway, and route tables. NAT, Elastic IP, security group, workspace storage, IAM, Databricks account resources, and compute have not been created. Bootstrap and later development stages remain separate operations.

The development design includes one NAT Gateway and one public IPv4 address. Both incur charges while allocated, even when no compute is running. Review current prices and the plan before any apply.

## Repository map

| Path | Responsibility |
| --- | --- |
| `infrastructure/bootstrap` | Creates the S3 bucket used for remote Terraform state. |
| `infrastructure/environments/dev` | Development root module and remote backend configuration point. |
| `infrastructure/modules/platform` | Composes networking, IAM, storage, and Databricks workspace modules. |
| `infrastructure/modules/networking` | VPC, subnets, routes, NAT Gateway, security group, and S3 endpoint. |
| `infrastructure/modules/iam` | AWS role and Databricks credential registration. |
| `infrastructure/modules/storage` | Private workspace root bucket and Databricks storage registration. |
| `infrastructure/modules/databricks-workspace` | Databricks network and workspace account resources. |
| `docs` | Project guide and operating references. |
| `diagrams` | Standalone architecture diagram. |
| `.devcontainer` | Reproducible local development environment. |
| `scripts` | Read-only verification and cleanup checks. |

## Operating boundary

Review the complete plan and confirm the AWS account, region, Databricks account, resources, and expected cost before any apply. Applying or destroying infrastructure requires explicit approval. See [deployment](docs/operations/deployment.md) and [cleanup](docs/operations/cleanup.md).
