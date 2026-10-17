# Documentation guide

The [repository README](../README.md) contains the project overview and current status. Use this page to find design references, procedures, and working notes.

## Documentation map

### Design

- [Architecture](design/architecture.md) describes components, ownership, and traffic flow.
- [Networking](design/networking.md) summarizes the CIDR plan, routing, and network controls.
- [Unity Catalog governance](design/unity-catalog-governance.md) describes the planned AWS storage, identity, namespace, and access-control model.

### Step by step

- [VPC foundation](step-by-step/vpc-foundation.md) explains CIDRs, VPCs, subnets, Internet Gateways, routes, and public IPv4 assignment.
- [Why Databricks Classic uses a NAT Gateway](step-by-step/why-nat-gateway-for-databricks.md) explains compute egress, AWS API access, S3 routing, and alternatives.

### Operations

- [Development environment](operations/development-environment.md) covers the devcontainer and local tools.
- [Deployment](operations/deployment.md) describes prerequisites, planning, deployment, and verification.
- [Cost estimation](operations/cost-estimation.md) records the lab cost assumptions.
- [Cleanup](operations/cleanup.md) describes resource teardown and residual checks.

### Reference

- [Project phases](reference/project-phases.md) tracks completed work and later phases.
- [Terraform state](reference/terraform-state.md) explains bootstrap and environment state.
- [Terraform modules and dependencies](reference/terraform-module-relationships.md) explains module inputs, generated IDs, dependency ordering, `depends_on`, locking, and drift.

### Learning notes

- [Terraform resource block](learning/terraform-resource-block.md) explains the basic resource declaration and how to reference a resource.

### Interview preparation

- [NAT Gateway](interview/nat-gateway.md) provides concise interview answers and outbound and inbound examples.

### Working notes

- [Project scratchpad](scratchpad.md) records local setup details and the next task.
