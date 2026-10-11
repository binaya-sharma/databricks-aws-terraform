# Deployment

This guide describes the deployment sequence. A command in the guide does not
approve an apply. Review each plan and get approval before applying it.

The development root creates the complete platform: VPC networking, NAT Gateway,
security group, S3 storage, IAM, and Databricks account resources. A normal
development apply is not a VPC-only deployment. The [VPC foundation guide](../step-by-step/vpc-foundation.md)
is a console learning walkthrough; it does not describe applying only part of
the Terraform root. Do not apply the complete development plan until Databricks
account access and all required values are ready. If deploying only networking,
first define and review a supported Terraform workflow for that scope.

For the current VPC foundation learning phase, a targeted Terraform plan can
show just the VPC, subnets, Internet Gateway, and routes. Terraform warns that
targeting is for exceptional workflows. Review the exact target addresses and
saved plan before any separately approved apply. This phase does not create the
NAT Gateway, Elastic IP, security group, S3 storage, IAM role, or Databricks
workspace.

```bash
terraform -chdir=infrastructure/environments/dev plan \
  -var-file=terraform.tfvars \
  -target=module.platform.terraform_data.network_validation \
  -target=module.platform.module.networking.aws_vpc.this \
  -target=module.platform.module.networking.aws_internet_gateway.this \
  -target=module.platform.module.networking.aws_subnet.public \
  -target=module.platform.module.networking.aws_subnet.private \
  -target=module.platform.module.networking.aws_route_table.public \
  -target=module.platform.module.networking.aws_route.public_internet \
  -target=module.platform.module.networking.aws_route_table_association.public \
  -target=module.platform.module.networking.aws_route_table.private \
  -target=module.platform.module.networking.aws_route_table_association.private \
  -out=vpc-foundation.tfplan

terraform -chdir=infrastructure/environments/dev show vpc-foundation.tfplan
```

Before applying this plan, confirm the active AWS identity, region, CIDRs, and
resource list. After this phase, a normal full plan will include the remaining
development platform resources. Do not apply that full plan until the later
networking phase and Databricks deployment are intended.

The S3 backend design and bucket lifecycle are documented in
[Terraform state](../reference/terraform-state.md). The local toolchain is documented in
[Development environment](development-environment.md).

## 1. Confirm prerequisites

1. Open the repository in the dev container.
2. Confirm the AWS account and caller identity.
3. Confirm the Databricks account ID and account-admin permission.
4. Confirm the Databricks subscription permits Classic workspaces.
5. Confirm the `us-west-2` AWS STS endpoint is active.
6. Confirm AWS quotas for a VPC, NAT Gateway, and Elastic IP address.
7. Confirm the development CIDRs do not overlap required networks.
8. Create AWS Budget alerts.

```bash
aws sts get-caller-identity --profile <profile-name>
aws configure get region --profile <profile-name>
databricks auth describe
```

## 2. Configure local values

Configure the `databricks-lab-admin` AWS profile using the [development environment guide](development-environment.md), then verify the account with `aws sts get-caller-identity --profile databricks-lab-admin`. Set `aws_profile = "databricks-lab-admin"` in the development variable file. Do not put AWS credentials in that file.

```bash
cp infrastructure/bootstrap/terraform.tfvars.example \
  infrastructure/bootstrap/terraform.tfvars
```

The development variables template is deferred with the Databricks setup files
under the local ignored `tmp/deferred` folder. Create the development variables
file only when its deployment scope and real Databricks account values are
ready. Do not put OAuth secrets in a variables file.

## 3. Validate without cloud changes

```bash
terraform fmt -recursive -check infrastructure
terraform -chdir=infrastructure/bootstrap init -backend=false
terraform -chdir=infrastructure/bootstrap validate
terraform -chdir=infrastructure/environments/dev init -backend=false
terraform -chdir=infrastructure/environments/dev validate
```

## 4. Bootstrap remote state after separate approval

```bash
terraform -chdir=infrastructure/bootstrap plan -out=bootstrap.tfplan
terraform -chdir=infrastructure/bootstrap show bootstrap.tfplan
terraform -chdir=infrastructure/bootstrap apply bootstrap.tfplan
```

Generate the development backend configuration:

```bash
terraform -chdir=infrastructure/bootstrap output -json \
  backend_hcl_by_environment | jq -r '.dev' \
  > infrastructure/environments/dev/backend.hcl
```

The bootstrap bucket has its own local state unless you configure a separate
backend for it. Protect and back up that local state. Do not destroy the bucket
while the development state is still needed.

## 5. Create and review the development plan

```bash
terraform -chdir=infrastructure/environments/dev init \
  -backend-config=backend.hcl -reconfigure

terraform -chdir=infrastructure/environments/dev plan -out=dev.tfplan
terraform -chdir=infrastructure/environments/dev show dev.tfplan
```

Check that the plan contains no cluster, EC2 instance, SQL warehouse, job, load
balancer, interface endpoint, or unexpected service. Confirm one NAT Gateway and
one Elastic IP address.

## 6. Apply only after separate approval

```bash
terraform -chdir=infrastructure/environments/dev apply dev.tfplan
```

Terraform references enforce the intended dependency order. No arbitrary sleep
is included. If AWS IAM propagation causes a documented Databricks credential
validation error, review the actual error before changing the configuration.

## 7. Verify without compute

```bash
scripts/verify.sh
```

Do not click a UI action that launches a cluster or warehouse. Cluster launch
capability remains configured but intentionally untested.
