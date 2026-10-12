# Deployment

The development Terraform root currently manages AWS networking only. Databricks IAM, workspace storage, and workspace modules are parked under `tobeimplement-temp/databricks/modules` and are not part of the active Terraform graph. The active networking module includes the VPC, subnets, NAT, security group, route tables, and optional S3 endpoint.

The VPC foundation and remaining AWS networking were applied and verified, then destroyed. The dev backend state is empty. A normal plan will propose recreating the AWS network; it should not contain Databricks account resources.

## Prerequisites

1. Use the devcontainer and confirm Terraform is available.
2. Verify the AWS identity and region.
3. Confirm the intended VPC CIDRs and two distinct Availability Zones.
4. Review quotas and create budget alerts before adding the NAT Gateway and public IPv4 address.

```bash
aws sts get-caller-identity --profile databricks-lab-admin
aws configure get region --profile databricks-lab-admin
```

## Configure local values

Copy the tracked example and replace its placeholders:

```bash
cp infrastructure/environments/dev/terraform.tfvars.example \
  infrastructure/environments/dev/terraform.tfvars
```

The actual local file is `infrastructure/environments/dev/terraform.tfvars`. Terraform loads it automatically when the command runs from that directory. The documented commands below also pass it explicitly with `-var-file=terraform.tfvars`, so the input source is visible. This file is ignored by Git. Keep Databricks account inputs and OAuth secrets out of it; those will be configured when that phase begins.

The S3 backend is already initialized. If the ignored `backend.hcl` is missing, regenerate it using the instructions in [Terraform state](../reference/terraform-state.md).

Terraform's S3 backend uses the AWS credential chain independently of the AWS provider settings in `terraform.tfvars`. Set the profile in the environment so backend operations, Terraform, and the AWS CLI use the same identity:

```bash
export AWS_PROFILE=databricks-lab-admin
```

## Validate

```bash
terraform fmt -recursive -check infrastructure
terraform -chdir=infrastructure/environments/dev validate
```

## Plan and review

Create a complete development plan and inspect it before applying:

```bash
AWS_PROFILE=databricks-lab-admin terraform -chdir=infrastructure/environments/dev plan \
  -var-file=terraform.tfvars -out=dev.tfplan
terraform -chdir=infrastructure/environments/dev show dev.tfplan
```

The plan should contain AWS networking resources only. Confirm every resource and expected cost. It must not include workspace storage, Databricks account resources, clusters, EC2 compute instances, SQL warehouses, jobs, load balancers, or unrelated services.

Targeted plans were used for the already-applied VPC foundation. Do not use a targeted plan as a substitute for reviewing the complete remaining configuration.

## Apply and verify

Apply only the reviewed plan after confirming the AWS account, deployment scope, and AWS credentials:

```bash
AWS_PROFILE=databricks-lab-admin terraform -chdir=infrastructure/environments/dev apply dev.tfplan
AWS_PROFILE=databricks-lab-admin scripts/verify.sh
```

The current phase does not create or start Databricks workspaces or compute.

For teardown, follow the ordered steps in [Cleanup](cleanup.md). Keep the bootstrap state bucket until development resources have been destroyed and verified.
