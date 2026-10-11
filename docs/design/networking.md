# Networking

For a console-based learning walkthrough covering VPC creation, subnet CIDRs, Internet Gateway routing, and public IPv4 assignment, see the [VPC foundation walkthrough](../step-by-step/vpc-foundation.md). This repository is managed by Terraform, so do not manually create the same project resources.

## Address plan

| Network | CIDR | Purpose |
| --- | --- | --- |
| VPC | `10.20.0.0/16` | Development lab |
| Public subnet | `10.20.1.0/24` | NAT Gateway only |
| Private subnet 1 | `10.20.11.0/24` | Databricks Classic Compute network |
| Private subnet 2 | `10.20.12.0/24` | Databricks Classic Compute network |

The `/24` private prefixes meet the current Databricks requirement that each
workspace subnet use a prefix from `/17` through `/26`. The two private subnets
must use different Availability Zones. Confirm that the VPC CIDR does not
overlap any connected VPC, VPN, office, or home lab network before apply.

## Routing

The public route table sends `0.0.0.0/0` to the Internet Gateway. The private
route table sends `0.0.0.0/0` to the single NAT Gateway. Both private subnets
share this route table.

The optional S3 gateway endpoint adds an AWS-managed S3 route to the private
route table. Gateway endpoints have no hourly endpoint charge and can avoid NAT
processing for in-region S3 traffic.

## Security group

The workspace security group has no public ingress. It allows all TCP and UDP
traffic only when the source or destination uses the same security group. It
allows documented outbound TCP ports for HTTPS, the legacy Hive metastore,
Lakebase, and Databricks control-plane communication.

Ports used only by PrivateLink, custom DNS, or the compliance security profile
are not added because those features are outside the lab scope.

## Network ACLs

The module uses the VPC default network access control list and does not create
restrictive subnet ACL rules. Databricks requires subnet ACLs not to deny the
required ingress and egress traffic.

## Why the compute subnets are private

Classic Compute nodes should not need direct public addresses or unsolicited
internet ingress. Private subnets reduce direct exposure while the NAT Gateway
provides outbound-only access to required Databricks and AWS endpoints.

Reference: [Databricks customer-managed VPC requirements](https://docs.databricks.com/aws/en/security/network/classic/customer-managed-vpc).
