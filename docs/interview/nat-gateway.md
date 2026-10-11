# Interview questions

This file collects questions that help explain the design and the reasoning behind it. Each answer starts with a concise response, followed by an example and useful follow-up points.

## Why does Databricks Classic use a NAT Gateway?

### Short answer

A NAT Gateway lets Databricks compute in private subnets initiate outbound connections to Databricks services and other required endpoints without assigning public IP addresses to the compute nodes.

### Say it this way

> Databricks Classic compute runs in private subnets and needs outbound connectivity to Databricks and required services. Its route table sends public IPv4 traffic through a NAT Gateway and Internet Gateway. This gives compute outbound access without assigning it public IP addresses or allowing unsolicited inbound internet connections.

### Examples

Outbound, similar to this design:

```text
Private compute node -> NAT Gateway -> Internet Gateway -> required service
```

Inbound, not used by this design:

```text
User on internet -> Internet Gateway -> public load balancer -> private application server
```

The NAT Gateway does not accept unsolicited inbound connections. Secure Cluster Connectivity uses an outbound connection from compute to the Databricks control plane. For detailed traffic flows and S3 routing, see [Why Databricks Classic uses a NAT Gateway](../step-by-step/why-nat-gateway-for-databricks.md).

### Useful follow-up points

- A NAT Gateway does not make the private subnet public. The private route table points to NAT, not directly to the Internet Gateway.
- A NAT Gateway permits connections initiated from the private subnet and their return traffic. It does not provide unsolicited inbound access to private instances.
- NAT is the conventional public-egress design, not the only possible architecture. A fully private design requires Databricks back-end PrivateLink and the necessary AWS service endpoints and routes.
- NAT Gateway hourly and data-processing charges apply while it is provisioned. See [Cost estimation](../operations/cost-estimation.md) for the lab estimate and [the NAT Gateway guide](../step-by-step/why-nat-gateway-for-databricks.md) for the single-AZ trade-off.

### How this applies to this repository

The planned design uses one zonal NAT Gateway for the development environment and an S3 Gateway Endpoint for same-region S3 traffic. The VPC foundation has been applied, but the NAT Gateway, Elastic IP, Databricks workspace, and compute have not yet been created.

## Why are the compute subnets private?

### Short answer

Private subnets keep compute nodes from receiving direct public IPv4 addresses while allowing controlled outbound connectivity through the selected network path.

### Example answer

> The compute nodes need to communicate with Databricks and required services, but they do not need direct inbound internet access. We place them in private subnets and route required outbound traffic through a NAT Gateway or approved private endpoints. Security groups and network ACLs provide additional traffic controls.

## Does the NAT Gateway let the Databricks control plane create EC2 instances?

### Short answer

No. The NAT Gateway carries data-plane network traffic from compute in the VPC. Databricks control-plane AWS resource operations use the configured cross-account IAM role, STS, and AWS APIs.

### Example answer

> The Databricks account uses an IAM role and STS to obtain permission to call AWS APIs for workspace infrastructure. Separately, once compute runs in the customer VPC, its outbound network traffic follows the VPC routes. IAM authorization and VPC routing solve different problems.

## Is a NAT Gateway required in every Databricks deployment?

### Short answer

No. The workspace subnets need an outbound path that meets Databricks requirements. A NAT Gateway is one common option. A fully private design can replace public egress with PrivateLink and the required AWS VPC endpoints, but it requires additional planning and configuration.

## Official references

- [Databricks customer-managed VPC requirements](https://docs.databricks.com/aws/en/security/network/classic/customer-managed-vpc)
- [Databricks classic compute networking](https://docs.databricks.com/aws/en/security/network/classic)
- [Databricks classic back-end PrivateLink](https://docs.databricks.com/aws/en/security/network/classic/privatelink)
- [AWS NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [AWS gateway endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-endpoints.html)
