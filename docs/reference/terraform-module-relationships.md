# Terraform modules and dependencies

This guide explains how Terraform passes configuration through this repository, how resource IDs flow between modules, and how Terraform decides creation order.

## Start at the development root

Terraform treats the `.tf` files in the directory where you run it as the root module. For this project, the development root is `infrastructure/environments/dev`.

The dev root configures the AWS and Databricks providers, calls the platform module, and exposes deployment outputs. See [dev root providers and platform call](../../infrastructure/environments/dev/main.tf#L18-L61).

The module hierarchy is:

```text
infrastructure/environments/dev  (root module)
└── infrastructure/modules/platform
    ├── infrastructure/modules/networking
    ├── infrastructure/modules/iam
    ├── infrastructure/modules/storage
    └── infrastructure/modules/databricks-workspace
```

The parent calls a child with a `module` block. The `source` path identifies the child module. Inputs in that block pass values into the child. The platform composition is in [platform `main.tf`](../../infrastructure/modules/platform/main.tf#L76-L137).

## How `name_prefix` is built and passed

The dev root declares `project_name` with the default `databricks-aws-terraform` and `environment` with the default `dev` in [dev variables](../../infrastructure/environments/dev/variables.tf#L13-L23). The dev root passes both into the platform module in [dev `main.tf`](../../infrastructure/environments/dev/main.tf#L47-L50).

The platform module combines them in a local value:

```hcl
name_prefix = "${var.project_name}-${var.environment}"
```

That produces `databricks-aws-terraform-dev`. The platform then passes `local.name_prefix` to networking, IAM, storage, and the workspace module. For example, the networking call passes it at [platform `main.tf`, networking inputs](../../infrastructure/modules/platform/main.tf#L76-L88). The networking module declares it as an input in [networking `variables.tf`](../../infrastructure/modules/networking/variables.tf).

The value is configured at the root and handed through the module calls. It is not independently set in every child module.

## How resource IDs are passed

Terraform and the cloud providers return IDs when resources are created. Each module can expose those values with `output` blocks, then the parent can pass the outputs to another module.

| Workspace input | Produced by | Code link |
| --- | --- | --- |
| `vpc_id` | AWS VPC resource in networking | [Networking output](../../infrastructure/modules/networking/outputs.tf#L1-L4) |
| `private_subnet_ids` | AWS private subnet resources in networking | [Networking output](../../infrastructure/modules/networking/outputs.tf#L11-L14) |
| `security_group_id` | AWS security group resource in networking | [Networking output](../../infrastructure/modules/networking/outputs.tf#L21-L24) |
| `credentials_id` | Databricks credential configuration created by IAM | [IAM resource](../../infrastructure/modules/iam/main.tf#L25-L33), [IAM output](../../infrastructure/modules/iam/outputs.tf#L11-L14) |
| `storage_configuration_id` | Databricks storage configuration created by storage | [Storage resource](../../infrastructure/modules/storage/main.tf#L59-L67), [storage output](../../infrastructure/modules/storage/outputs.tf#L11-L14) |

The platform passes these values into the workspace module in [platform `main.tf`](../../infrastructure/modules/platform/main.tf#L125-L134). The workspace module uses them in its Databricks resources in [workspace `main.tf`](../../infrastructure/modules/databricks-workspace/main.tf).

You do not copy these generated IDs into `terraform.tfvars`. On the first plan, Terraform may show an ID as `known after apply`. Terraform creates the prerequisite resource, receives the ID from AWS or Databricks, and supplies it to the dependent resource. Later plans can read the existing IDs from Terraform state and refresh them against the providers.

Values such as the Databricks account ID, workspace name, AWS region, and CIDR ranges are configuration inputs. The resource IDs above are generated outputs.

## How Terraform orders resources

Terraform builds a dependency graph from references.

For example, the NAT Gateway uses `aws_eip.nat.id` and `aws_subnet.public.id` in [networking `main.tf`](../../infrastructure/modules/networking/main.tf#L42-L55). Those references tell Terraform to create the Elastic IP and public subnet before the NAT Gateway. The workspace resource uses the network ID created by its network registration resource in [workspace `main.tf`](../../infrastructure/modules/databricks-workspace/main.tf), so the network registration must happen first.

These are **implicit dependencies**. A resource or module references another object's value, so Terraform can infer the ordering.

## What `depends_on` does

Use `depends_on` for a dependency Terraform cannot infer from an argument reference. It adds an explicit ordering edge to the graph.

This repository has two examples:

- Networking waits for CIDR and Availability Zone validation in [platform `main.tf`](../../infrastructure/modules/platform/main.tf#L76-L88).
- The workspace module explicitly waits for the networking module in [platform `main.tf`](../../infrastructure/modules/platform/main.tf#L118-L137).
- The NAT Gateway explicitly waits for the Internet Gateway in [networking `main.tf`](../../infrastructure/modules/networking/main.tf#L48-L55).

An explicit module dependency waits for the module's operations as a whole. That is broader than a reference to one output and can make a plan more conservative. Prefer references when they express the required relationship; add `depends_on` when there is a real hidden dependency.

## State locking and drift

The dev root stores state in S3. The generated backend configuration sets `use_lockfile = true` in [bootstrap outputs](../../infrastructure/bootstrap/outputs.tf#L11-L21). Terraform uses that lock to prevent two Terraform operations from writing the same state at once. The bootstrap root itself uses local state.

State locking does not stop manual changes in AWS or Databricks. Those changes can create **drift**, where real resources differ from configuration. A normal `terraform plan` refreshes the provider view and shows proposed changes. Review the plan to decide whether to update the configuration or let Terraform restore the configured values.

## A safe way to explore

From the repository root, inspect the dev root and then follow one value through each module:

1. Find a root variable in `infrastructure/environments/dev/variables.tf`.
2. Find where the dev root passes it to `module.platform`.
3. Find where the platform module uses it directly or passes it to a child.
4. For generated IDs, trace the resource, its module output, and the parent's input assignment.
5. Follow resource references and `depends_on` to understand ordering.

Run `terraform plan` from the dev root to see the full dependency graph expressed as proposed actions. Review the complete plan; this root includes networking, IAM, storage, and Databricks resources.
