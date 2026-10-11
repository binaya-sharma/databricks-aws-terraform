# Project guidelines and implementation plan

This file contains the working rules for the repository. Keep all documentation
simple, current, and safe for a new contributor to follow.

## Current scope

Only the `dev` environment is implemented. The current work covers preparation,
Terraform implementation, validation, documentation, and read-only scripts.
It does not authorize `terraform apply` or any cloud resource creation.

The planned promotion path remains:

1. Build and verify `dev` first.
2. Design `qa` only after the development deployment and cleanup are proven.
3. Design `prod` only after the QA workflow and isolation requirements are clear.

Do not copy the development configuration into `qa` or `prod` yet. Future
environments should call the shared platform module and use separate accounts,
roles, state, and approvals where practical.

## Implementation phases

### Phase 0: research and planning

- Validate current Databricks networking and account prerequisites.
- Confirm AWS and Databricks authentication.
- Confirm Classic workspace plan and billing access.
- Review the 72-hour cost estimate.

### Phase 1: networking

- Create the VPC, subnets, routes, NAT Gateway, security group, and S3 endpoint.
- Validate the code without deploying it.

### Phase 2: IAM and storage

- Create the cross-account IAM role using provider policy templates.
- Create private workspace root storage using the provider bucket template.
- Validate the code without deploying it.

### Phase 3: Databricks account resources

- Register credentials, storage, and network configurations.
- Define the Classic workspace.
- Do not define compute resources.

### Phase 4: documentation and safe operations

- Document architecture, networking, costs, deployment, and cleanup.
- Provide read-only verification and cleanup checks.

### Phase 5: deployment

- Start only after explicit user approval.
- Apply bootstrap and development plans separately.
- Verify workspace status without launching compute.

### Phase 6: destruction

- Start only after explicit user approval.
- Destroy development resources before remote-state resources.
- Run read-only cleanup checks.

## Terraform rules

1. Keep the bootstrap state separate from development platform state.
2. Commit provider lock files.
3. Run `terraform fmt`, `terraform validate`, and `terraform plan` before apply.
4. Review every plan and confirm the AWS account and region.
5. Do not hardcode access keys, OAuth secrets, or tokens.
6. Use provider-generated Databricks IAM and bucket policy templates.
7. Do not create clusters, jobs, warehouses, or EC2 instances in this project.
8. Do not add paid interface endpoints or PrivateLink to the initial lab.
9. Preserve the single NAT Gateway design unless the budget is reviewed again.
10. Use resource references for ordering. Do not add arbitrary sleeps.
11. Add no public ingress to the Databricks workspace security group.
12. Keep resources tagged with project, environment, owner, purpose, and manager.
13. Never apply or destroy without explicit user approval.

## Documentation rules

1. Use plain English and short sentences.
2. Present operational work as numbered steps.
3. Define abbreviations on first use.
4. Use placeholders instead of real IDs or secrets.
5. Link to official documentation for external requirements.
6. State cost assumptions and review dates.
7. Do not use an em dash character.
8. Avoid claims that this lab is production ready.
9. Update related documentation when behavior changes.

## Ownership boundaries

| Layer | Owner |
| --- | --- |
| Bootstrap | Remote Terraform state bucket |
| AWS modules | VPC, routing, NAT, IAM, and S3 |
| Databricks account module | Credentials, storage, network registration, and workspace |
| Future workspace module | Workspace objects, only if added later |
| Operator | Authentication, plan approval, apply approval, verification, and cleanup |

Do not manage the same resource manually and with Terraform. If an emergency
manual change occurs, reconcile it back into code or import it before continuing.

## Official references

- [Databricks customer-managed VPC requirements](https://docs.databricks.com/aws/en/security/network/classic/customer-managed-vpc)
- [Databricks manual workspace creation](https://docs.databricks.com/aws/en/admin/workspace/create-uc-workspace)
- [Databricks OAuth M2M](https://docs.databricks.com/aws/en/dev-tools/auth/oauth-m2m)
- [Databricks Terraform AWS workspace guide](https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/aws-workspace)
- [AWS VPC pricing](https://aws.amazon.com/vpc/pricing/)
- [AWS subnet sizing](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html)
- [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)
