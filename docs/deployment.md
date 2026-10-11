# Deployment

No command in this guide authorizes an apply. Stop after planning until explicit
approval is given.

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

```bash
cp infrastructure/bootstrap/terraform.tfvars.example \
  infrastructure/bootstrap/terraform.tfvars

cp infrastructure/environments/dev/terraform.tfvars.example \
  infrastructure/environments/dev/terraform.tfvars
```

Replace every placeholder. Do not place OAuth secrets in either file.

## 3. Validate without cloud changes

```bash
terraform fmt -recursive -check infrastructure
terraform -chdir=infrastructure/bootstrap init -backend=false
terraform -chdir=infrastructure/bootstrap validate
terraform -chdir=infrastructure/environments/dev init -backend=false
terraform -chdir=infrastructure/environments/dev validate
```

## 4. Bootstrap remote state after approval

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
