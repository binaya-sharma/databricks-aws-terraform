# Development environment

## Purpose

The devcontainer provides a consistent shell and Terraform toolchain for working on this repository. It does not authenticate to AWS or Databricks automatically, and opening the container does not create cloud resources.

## Repository files

| File | Purpose |
| --- | --- |
| `.devcontainer/devcontainer.json` | VS Code container configuration and mounted settings. |
| `.devcontainer/Dockerfile` | Container image and installed command line tools. |
| `.devcontainer/scripts/post-create.sh` | Setup run after the container is created. |
| `.dockerignore` | Files excluded from the container build context. |

## Open the container

1. Install Docker Desktop and Visual Studio Code with the Dev Containers extension.
2. Open the repository folder in VS Code.
3. Run **Dev Containers: Reopen in Container**.
4. Review the versions installed in the Dockerfile if a command behaves differently than expected.

The devcontainer stores AWS configuration in a named Docker volume mounted at `/home/vscode/.aws`. This keeps credentials out of the Git repository and preserves them when the container is rebuilt. Anyone with access to the Docker host may still be able to access that volume.

## Configure AWS authentication

Use AWS IAM Identity Center when it is available. It provides temporary credentials and avoids long lived access keys:

```bash
aws configure sso --profile databricks-lab-admin
aws sso login --profile databricks-lab-admin
aws sts get-caller-identity --profile databricks-lab-admin
```

If this account is an IAM user and you already have an access key for it, configure a named profile inside the devcontainer:

```bash
aws configure --profile databricks-lab-admin
aws sts get-caller-identity --profile databricks-lab-admin
```

The CLI prompts for the access key ID, secret access key, default region, and output format. Enter them directly into the local prompt. Do not send them in chat, put them in Terraform variables, or commit `~/.aws` files. Use `us-east-1` as the default region for this project. The AWS profile stores authentication settings, while the Terraform variables select the infrastructure region.

The IAM user's administrator permissions allow broad changes across the account. Use a dedicated user or role for this learning project where possible, protect the credentials, and remove any access key that is no longer needed. Do not use the AWS root user for CLI access.

The STS identity check confirms which account and principal the profile uses. It does not prove that the principal has every permission required by the Terraform plan. Review the plan and the account before applying.

## Configure Databricks authentication

Terraform uses Databricks unified authentication. Configure the account OAuth machine to machine credentials in the shell environment, or use the Databricks CLI for interactive administration. Keep client secrets out of files tracked by Git.

See the [deployment guide](deployment.md) for complete prerequisites and the [project guide](../README.md) for repository conventions.

## Useful local checks

These commands format and validate Terraform without creating cloud resources:

```bash
terraform fmt -recursive -check infrastructure
terraform -chdir=infrastructure/bootstrap init -backend=false
terraform -chdir=infrastructure/bootstrap validate
terraform -chdir=infrastructure/environments/dev init -backend=false
terraform -chdir=infrastructure/environments/dev validate
```
