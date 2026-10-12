# Terraform resource block

A Terraform resource block declares an infrastructure object managed by a provider.

```hcl
resource "RESOURCE_TYPE" "RESOURCE_NAME" {
  # Resource-specific arguments go here.
}
```

Replace `RESOURCE_TYPE` with a provider resource type, such as `aws_vpc`, and `RESOURCE_NAME` with a Terraform-local label. For example:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.20.0.0/16"
}
```

The local label `main` is used in Terraform references, such as `aws_vpc.main.id`. The provider creates the actual AWS resource and returns its generated ID.
