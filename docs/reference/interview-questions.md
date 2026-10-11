# Interview questions

This file collects questions that help explain the design and the reasoning behind it. Each answer starts with a concise response, followed by an example and useful follow-up points.

## Why does Databricks Classic use a NAT Gateway?

### Short answer

A NAT Gateway lets Databricks compute in private subnets initiate outbound connections to Databricks services and other required endpoints without assigning public IP addresses to the compute nodes.

### Example answer

> Databricks Classic compute runs on EC2 instances in our private subnets. Those instances need outbound connectivity for control-plane communication and required AWS or external services. The private route table sends their default IPv4 traffic to a NAT Gateway in a public subnet. The NAT Gateway uses an Elastic IP and routes through the Internet Gateway. The compute nodes keep private IP addresses and do not accept unsolicited connections from the internet.

### Example traffic flow

```text
Databricks compute node
  -> private subnet route table
  -> NAT Gateway
  -> Internet Gateway
  -> required public endpoint
```

The NAT Gateway provides network translation and outbound routing. IAM roles, AWS Security Token Service (STS), and AWS APIs handle authorization and resource provisioning. These are separate flows.

Same-region Amazon S3 traffic can use an S3 Gateway VPC Endpoint instead of the NAT Gateway. AWS adds a service prefix-list route to the selected route table, and the more-specific route is used for matching S3 destinations.

### Useful follow-up points

- A NAT Gateway does not make the private subnet public. The private route table points to NAT, not directly to the Internet Gateway.
- A NAT Gateway permits connections initiated from the private subnet and their return traffic. It does not provide unsolicited inbound access to private instances.
- NAT is the conventional public-egress design, not the only possible architecture. A fully private design requires Databricks back-end PrivateLink and the necessary AWS service endpoints and routes.
- NAT Gateway hourly and data-processing charges apply while it is provisioned. The public IPv4 address also has a charge. One NAT Gateway is a cost trade-off and a single-AZ dependency.

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
