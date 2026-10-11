# VPC foundation walkthrough

## Scope

This guide covers the first networking layer: an Amazon Virtual Private Cloud (VPC), its IPv4 address plan, subnets, an Internet Gateway (IGW), route tables, and subnet public IPv4 auto-assignment.

It does not create an Elastic IP address, a NAT Gateway, security groups, or custom network access control lists (network ACLs). Those are later steps. This guide is a learning procedure and does not authorize a Terraform apply or console changes.

The repository's Terraform configuration is the source of truth for the project VPC. Use a separate temporary VPC if you want to practice these console steps. Do not create the Terraform-managed resources manually and then manage the same resources with Terraform.

## What the first layer will contain

| Component | Development value | Purpose |
| --- | --- | --- |
| Region | `us-east-1` | Region where the VPC and subnets live. |
| VPC CIDR | `10.20.0.0/16` | Address space reserved for this network. |
| Public subnet | `10.20.1.0/24` in one Availability Zone | Future location for the NAT Gateway. |
| Private subnet 1 | `10.20.11.0/24` in one Availability Zone | Future Databricks Classic Compute network. |
| Private subnet 2 | `10.20.12.0/24` in a different Availability Zone | Future Databricks Classic Compute network. |
| IGW | Attached to the VPC | Route target for internet-bound traffic from a public subnet. |
| Public route table | Associated only with the public subnet | Has the VPC local route and an IPv4 default route to the IGW. |
| Private route table | Associated with both private subnets | Initially has only the VPC local route. A NAT route is a later step. |

AWS reserves five IPv4 addresses in every subnet. A `/24` has 256 total addresses and 251 available for resources. Do not allocate the reserved addresses yourself.

## Plan the CIDR ranges

CIDR means Classless Inter-Domain Routing. The number after the slash is the count of network bits. The remaining bits are available for addresses within that range.

For example, `10.20.0.0/16` contains 65,536 IPv4 addresses. A `/24` contains 256 addresses. A subnet must fit inside the VPC range, and subnet ranges in one VPC must not overlap.

This project uses the following ranges:

| Range | Address span | Total addresses |
| --- | --- | ---: |
| `10.20.0.0/16` | `10.20.0.0` through `10.20.255.255` | 65,536 |
| `10.20.1.0/24` | `10.20.1.0` through `10.20.1.255` | 256 |
| `10.20.11.0/24` | `10.20.11.0` through `10.20.11.255` | 256 |
| `10.20.12.0/24` | `10.20.12.0` through `10.20.12.255` | 256 |

Before choosing a CIDR, compare it with every network that may connect to this VPC, including other VPCs, VPNs, office networks, and home labs. Overlapping ranges make routing between those networks difficult or impossible.

The project uses two `/24` workspace subnets in different Availability Zones. AWS assigns Availability Zone letters per account, so check the available zones in the target account and choose two distinct zones in `us-east-1`.

## Console procedure

Use the AWS console in the intended account and region. Confirm the account identity and select `us-east-1` before creating anything.

### 1. Create the VPC

1. Open the [Amazon VPC console](https://console.aws.amazon.com/vpc/).
2. Choose **Your VPCs**, then **Create VPC**.
3. For **Resources to create**, select **VPC only**. This walkthrough creates the pieces separately so each one is easy to understand.
4. Set the name to `databricks-aws-terraform-dev`.
5. Choose **IPv4 CIDR manual input** and enter `10.20.0.0/16`.
6. Leave IPv6 CIDR allocation disabled for this first pass.
7. Leave tenancy at **Default**.
8. Create the VPC.
9. Select the VPC, choose **Actions**, then **Edit VPC settings**. Enable **DNS resolution** and **DNS hostnames**, then save.

AWS creates a main route table with a local route for communication inside the VPC. The VPC does not have internet access just because it exists.

### 2. Create three subnets

Create the subnets from **Subnets**, using **Create subnet** for each one. Select the new VPC each time.

| Subnet name | Availability Zone | IPv4 subnet CIDR | Auto-assign public IPv4 for this project |
| --- | --- | --- | --- |
| `databricks-aws-terraform-dev-public-nat` | First selected zone | `10.20.1.0/24` | Disabled |
| `databricks-aws-terraform-dev-private-1` | First selected zone | `10.20.11.0/24` | Disabled |
| `databricks-aws-terraform-dev-private-2` | A different zone | `10.20.12.0/24` | Disabled |

The public and first private subnet may use the same Availability Zone. The two Databricks private subnets must be in different zones.

For each subnet:

1. Enter its name and select its Availability Zone.
2. Enter the exact IPv4 CIDR from the table.
3. Leave IPv6 settings disabled for this first pass.
4. Create the subnet.
5. Check that the subnet's VPC ID and CIDR match the plan.

### 3. Create and attach the IGW

1. In the VPC console, choose **Internet gateways**, then **Create internet gateway**.
2. Name it `databricks-aws-terraform-dev-igw` and create it.
3. Select it, choose **Actions**, then **Attach to a VPC**.
4. Select the VPC created in step 1 and attach the IGW.

An attached IGW is only a route target. It does not make every subnet public.

### 4. Create the public route table

1. Choose **Route tables**, then **Create route table**.
2. Name it `databricks-aws-terraform-dev-public` and select the project VPC.
3. Create the route table.
4. Select it and open **Routes**, then **Edit routes**.
5. Add destination `0.0.0.0/0` with the attached IGW as the target.
6. Save the route.
7. Open **Subnet associations**, choose **Edit subnet associations**, select only the public subnet, and save.

The table should contain these routes:

| Destination | Target | Meaning |
| --- | --- | --- |
| `10.20.0.0/16` | `local` | Traffic within the VPC stays in the VPC. AWS creates this route automatically. |
| `0.0.0.0/0` | The project IGW | Other IPv4 destinations use the IGW. |

### 5. Create the private route table

1. Create another route table named `databricks-aws-terraform-dev-private` in the project VPC.
2. Do not add a default route to the IGW.
3. Open **Subnet associations**, select both private subnets, and save.

For this first phase, the private table should contain only the VPC local route. Later, a NAT Gateway can be added as the target of `0.0.0.0/0` for private outbound access. Do not use the IGW directly as the private subnets' default route.

### 6. Understand subnet auto-assigned public IPv4

The VPC console can set a subnet attribute that requests a public IPv4 address for an instance launched into that subnet:

1. Choose **Subnets** and select the subnet.
2. Choose **Actions**, then **Edit subnet settings**.
3. Review **Enable auto-assign public IPv4 address**.
4. Save only if the setting is part of the intended design.

This setting controls address assignment. It does not create an IGW route, and it does not make a subnet public on its own. A resource needs both a route to the IGW and a public address for direct IPv4 internet communication. Security group and network ACL rules also affect whether traffic is allowed.

In this repository, auto-assignment is intentionally disabled on all three subnets. The public subnet is reserved for a future NAT Gateway, which will use an Elastic IP address. The private subnets are for Databricks network interfaces. Terraform currently sets `map_public_ip_on_launch = false`; enabling it manually on the project VPC would create configuration drift. We can decide whether that Terraform setting should change before deployment.

## How routes classify public and private subnets

A route table is a set of destination and target rules. Every subnet uses exactly one route table at a time. It uses an explicitly associated table when one is set; otherwise, it uses the VPC's main route table.

AWS calls a subnet public when its associated route table has a route to an IGW. AWS calls it private when its associated route table has no route to an IGW. The subnet's name, CIDR, and public IPv4 auto-assignment setting do not determine this classification.

For IPv4, `0.0.0.0/0` means every IPv4 destination. AWS selects the most specific matching route. The VPC's local route is more specific than the default route, so traffic to `10.20.0.0/16` stays inside the VPC while other IPv4 traffic follows the `0.0.0.0/0` target.

| Route table | Routes after this phase | Subnet type |
| --- | --- | --- |
| Public | VPC CIDR to `local`; `0.0.0.0/0` to IGW | Public |
| Private | VPC CIDR to `local` only | Private and isolated from internet routes |

Later, the private route table will get `0.0.0.0/0` to a NAT Gateway. It remains private because its route points to NAT, not directly to the IGW.

## Check the result

Before considering this phase complete, verify:

1. The VPC CIDR is `10.20.0.0/16` and DNS resolution and hostnames are enabled.
2. All three subnet CIDRs are inside the VPC and do not overlap.
3. The two private subnets are in different Availability Zones.
4. The IGW is attached to this VPC.
5. The public route table is associated only with the public subnet and has `0.0.0.0/0` to the IGW.
6. The private route table is associated with both private subnets and has no route to the IGW.
7. Public IPv4 auto-assignment is disabled for the project subnets, matching Terraform.

No instances are needed to complete these checks. This phase creates no compute.

## What is deferred

The next networking phase will cover an Elastic IP address, NAT Gateway, security group rules, and network ACL behavior. The private route table will then receive its outbound route to the NAT Gateway. Do not proceed with that phase until the network foundation and address plan have been reviewed.

## Official references

- [Create a VPC](https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc.html)
- [VPC CIDR blocks](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html)
- [IP addressing for VPCs and subnets](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-ip-addressing.html)
- [Create a subnet](https://docs.aws.amazon.com/vpc/latest/userguide/create-subnets.html)
- [Create and configure a route table](https://docs.aws.amazon.com/vpc/latest/userguide/create-vpc-route-table.html)
- [Subnet route tables](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-route-tables.html)
- [Add internet access with an IGW](https://docs.aws.amazon.com/vpc/latest/userguide/working-with-igw.html)
- [Modify subnet IP addressing attributes](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-public-ip.html)
- [Update VPC DNS attributes](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns-updating.html)
