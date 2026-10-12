# Cleanup

The dev root currently manages AWS networking only. Its destroy does not remove the separate bootstrap S3 bucket that stores remote Terraform state.

## Review and destroy dev networking

Capture resource identifiers before destroy:

```bash
AWS_PROFILE=databricks-lab-admin scripts/verify.sh
```

Create and inspect a destroy plan from the dev root:

```bash
AWS_PROFILE=databricks-lab-admin terraform -chdir=infrastructure/environments/dev plan \
  -destroy -input=false -var-file=terraform.tfvars -out=/tmp/dev-destroy.tfplan
terraform -chdir=infrastructure/environments/dev show /tmp/dev-destroy.tfplan
```

Confirm the plan targets only this project's dev networking resources. Apply the reviewed plan:

```bash
AWS_PROFILE=databricks-lab-admin terraform -chdir=infrastructure/environments/dev apply \
  -input=false /tmp/dev-destroy.tfplan
```

## Verify cleanup

Run the read-only residual checks:

```bash
AWS_PROFILE=databricks-lab-admin scripts/check-cleanup.sh
```

The check uses `.artifacts/dev-deployment.json`, recorded before destroy, to verify the VPC, NAT Gateway, Elastic IP, security group, S3 Gateway Endpoint, and tagged EC2 and EBS resources. It never deletes anything. Review AWS billing and confirm the NAT Gateway and public IPv4 charges have stopped.

## Preserve the bootstrap backend

Keep the bootstrap S3 state bucket and local bootstrap state while you may recreate the dev environment. The dev state remains in the bucket after its managed resources are destroyed, which lets Terraform track the empty environment and later provision it again.

Retiring the bootstrap bucket is a separate final action. It deletes remote state history and requires setting `force_destroy_state_bucket = true`; do that only when you are retiring the project and no longer need the backend.
