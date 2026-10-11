# Cleanup

Cleanup is part of the lab, not an optional final task.

## 1. Capture exact resource identifiers

Run before destroy:

```bash
scripts/verify.sh
```

This writes non-sensitive identifiers to `.artifacts/dev-deployment.json`. The
directory is ignored by Git.

## 2. Review a development destroy plan

```bash
terraform -chdir=infrastructure/environments/dev plan -destroy \
  -out=destroy.tfplan
terraform -chdir=infrastructure/environments/dev show destroy.tfplan
```

Confirm the plan targets only development resources owned by this project.
Never delete resources using broad name matching.

## 3. Destroy development after approval

```bash
terraform -chdir=infrastructure/environments/dev apply destroy.tfplan
```

The workspace must be deleted before the Databricks network, storage, and
credential configuration objects. Terraform derives this order from references.
The S3 workspace root bucket uses `force_destroy` for this disposable lab, so
Terraform can remove provider-created objects and versions.

## 4. Run read-only residual checks

```bash
scripts/check-cleanup.sh
```

The script checks the exact recorded VPC, NAT Gateway, Elastic IP, IAM role, S3
bucket, workspace, and project-tagged EC2 and EBS resources. It never deletes
anything.

Review the AWS Billing console, Cost Explorer, Elastic IP addresses, NAT
Gateways, S3 buckets, IAM roles, EC2 instances, and EBS volumes after the script.
Also review the Databricks account console for failed or deleting workspaces.

## 5. Retire remote state last

Only after development cleanup succeeds:

```bash
terraform -chdir=infrastructure/bootstrap plan -destroy \
  -out=bootstrap-destroy.tfplan
terraform -chdir=infrastructure/bootstrap show bootstrap-destroy.tfplan
terraform -chdir=infrastructure/bootstrap apply bootstrap-destroy.tfplan
```

`force_destroy_state_bucket` must be `true` for a complete lab teardown. This
deletes all state object versions and removes the recovery history. Save any
required non-secret evidence before this final step.

Do not cancel a Databricks plan as part of normal workspace cleanup. Plan
cancellation affects the whole account and is not equivalent to deleting this
project's workspace.
