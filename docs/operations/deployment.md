# Deployment

The development Terraform root manages the full platform: VPC networking, NAT, security group, AWS storage and IAM, and Databricks account resources. A normal plan and apply is not a networking-only operation. Review the entire plan and confirm the target AWS and Databricks accounts before applying.

The [VPC foundation](../step-by-step/vpc-foundation.md) is already applied. The current next phase is the remaining network resources. Do not use a normal full apply until the Databricks resources in its plan are intended as well.

## Prerequisites

1. Use the devcontainer and confirm Terraform is available.
2. Verify the AWS identity and region.
3. Confirm the intended VPC CIDRs and two distinct Availability Zones.
4. For a full workspace deployment, confirm Databricks account admin access, Classic workspace eligibility, account ID, and OAuth machine-to-machine credentials.
5. Review quotas and create budget alerts before adding the NAT Gateway and public IPv4 address.

```bash
aws sts get-caller-identity --profile databricks-lab-admin
aws configure get region --profile databricks-lab-admin
databricks auth describe
```

## Configure local values

Create `infrastructure/environments/dev/terraform.tfvars` using the required inputs in the tracked `variables.tf` and real account values. A deferred example template may exist under the local ignored `tmp/deferred` directory, but it is not distributed with the repository. Do not put OAuth secrets in Terraform variable files. Set the AWS profile to `databricks-lab-admin` or use the AWS credential chain.

The S3 backend is already initialized. If the ignored `backend.hcl` is missing, regenerate it using the instructions in [Terraform state](../reference/terraform-state.md).

## Validate

```bash
terraform fmt -recursive -check infrastructure
terraform -chdir=infrastructure/environments/dev validate
```

## Plan and review

Create a complete development plan and inspect it before applying:

```bash
terraform -chdir=infrastructure/environments/dev plan -out=dev.tfplan
terraform -chdir=infrastructure/environments/dev show dev.tfplan
```

The full plan may include a NAT Gateway, Elastic IP, security group, S3 endpoint, workspace root bucket, IAM role, Databricks credentials, network registration, and workspace. Confirm every resource and the expected cost. It must not include clusters, EC2 compute instances, SQL warehouses, jobs, load balancers, or unrelated services.

Targeted plans were used for the already-applied VPC foundation. Do not use a targeted plan as a substitute for reviewing the complete remaining configuration.

## Apply and verify

Apply only the reviewed plan after the deployment scope and all credentials are ready:

```bash
terraform -chdir=infrastructure/environments/dev apply dev.tfplan
scripts/verify.sh
```

Do not start a cluster or SQL warehouse during verification. Workspace provisioning does not require launching compute.

For teardown, follow the ordered steps in [Cleanup](cleanup.md). Keep the bootstrap state bucket until development resources have been destroyed and verified.
