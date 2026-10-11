# Architecture

## Objective

Provision one temporary Databricks Classic workspace in `us-east-1` with a
Terraform-managed customer VPC. Configure future Classic Compute connectivity
without creating or starting compute.

## Scope and ownership

The repository has two Terraform roots. `infrastructure/bootstrap` manages the
S3 bucket for remote environment state. `infrastructure/environments/dev`
manages the development platform. Shared modules under
`infrastructure/modules` compose the network, IAM, storage, and Databricks
account resources. See [Terraform state](../reference/terraform-state.md) for the state
lifecycle.

## Component flow

1. Terraform uses the local AWS identity to create VPC, IAM, and S3 resources.
2. Terraform uses a Databricks account service principal to call account APIs.
3. Databricks assumes the cross-account IAM role using the account ID as an
   external ID.
4. Databricks registers the two private subnets and security group as a network
   configuration.
5. Databricks registers the private S3 bucket as workspace root storage.
6. Databricks creates the workspace from the credential, network, and storage
   IDs.
7. Future Classic Compute would use private subnet addresses and the NAT Gateway
   for required outbound control-plane connectivity.

The cross-account role is not the identity that runs Terraform. It grants the
Databricks control plane the documented permissions required to manage future
Classic Compute resources in this AWS account. A future workload data-access
role would be separate and is not part of this lab.

## Availability trade-off

Databricks requires two private workspace subnets in distinct Availability
Zones. The lab plans one NAT Gateway in the first zone. If that zone fails,
outbound connectivity can fail for both subnets. See [Cost estimation](../operations/cost-estimation.md)
for the cost assumptions and [the NAT Gateway guide](../step-by-step/why-nat-gateway-for-databricks.md)
for the design alternatives.

## Excluded services

The design excludes EC2 instances, Databricks clusters, SQL warehouses, jobs,
load balancers, interface endpoints, PrivateLink, customer-managed encryption
keys, and optional logging services.
