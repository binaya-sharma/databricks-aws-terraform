# Terraform state and AWS bootstrap

## Purpose

Terraform state records the resources managed by each configuration. This repository uses two separate states:

| State | Terraform root | Location | Purpose |
| --- | --- | --- | --- |
| Bootstrap | `infrastructure/bootstrap` | Local state by default | Creates the S3 bucket used by environment states. |
| Development | `infrastructure/environments/dev` | S3 object configured by `backend.hcl` | Tracks the development platform and Databricks workspace. |

The bootstrap state must remain available while the development state bucket is in use. The bootstrap configuration currently uses local state unless a backend is configured separately. Protect that local state file and keep a secure backup.

## What the bootstrap configuration creates

The bootstrap Terraform root creates one S3 bucket. It enables bucket owner enforced ownership, blocks public access, enables versioning, and encrypts objects with Amazon S3 managed keys. It also outputs backend settings for `dev`, `qa`, and `prod`.

The `qa` and `prod` backend keys are placeholders for future environments. Their existence does not mean those environments are implemented.

The bucket name is generated from the project name, environment, AWS account ID, and a random suffix unless `state_bucket_name` is set. S3 bucket names are globally unique. Confirm the selected AWS account and region before planning.

## Create the state bucket

Follow the prerequisites and validation steps in the [deployment guide](../operations/deployment.md). After separately reviewing and approving the bootstrap plan, run:

```bash
terraform -chdir=infrastructure/bootstrap plan -out=bootstrap.tfplan
terraform -chdir=infrastructure/bootstrap show bootstrap.tfplan
terraform -chdir=infrastructure/bootstrap apply bootstrap.tfplan
```

Confirm that the plan creates only the intended state bucket and related bucket configuration. Save the bootstrap state file and record the bucket name and region in a secure operational record.

## Configure the development backend

Export the generated backend settings and initialize the development root:

```bash
terraform -chdir=infrastructure/bootstrap output -json \
  backend_hcl_by_environment | jq -r '.dev' \
  > infrastructure/environments/dev/backend.hcl

terraform -chdir=infrastructure/environments/dev init \
  -backend-config=backend.hcl -reconfigure
```

`backend.hcl` contains bucket and key names, not credentials. The file is generated locally and should not be committed. AWS authentication comes from the AWS provider and CLI credential chain.

The S3 backend uses encryption and Terraform's S3 lockfile support. Use Terraform 1.10 or later, as required by the project.

## State handling rules

1. Never edit a state file by hand.
2. Do not commit state, plan files, backend configuration, or generated variable files.
3. Keep state access limited to the operator identity used for this project.
4. Back up the bootstrap state before changing or retiring the state bucket.
5. Do not remove the state bucket while any environment state is still needed.
6. Treat state as sensitive. It can contain resource identifiers and values returned by providers even when outputs are marked sensitive.
7. Reinitialize with `-reconfigure` only when intentionally changing backend settings.

## Retire state after environment cleanup

Destroy and verify the development environment first. Review [cleanup](../operations/cleanup.md) for the full order. Only after all environment resources are gone and required state history is no longer needed should you plan destruction of the bootstrap bucket.

The bootstrap variable `force_destroy_state_bucket` defaults to `false`. Setting it to `true` permits Terraform to delete all object versions in the bucket. The example variable file currently sets it to `true` for a complete disposable lab teardown. Keep it `false` while the bucket holds state that must be retained.

## References

- [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Terraform S3 backend locking](https://developer.hashicorp.com/terraform/language/backend/s3#state-locking)
