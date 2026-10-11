resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-nat"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${count.index + 1}"
    Tier = "private"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-public" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-private" })
}

resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  count = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "workspace" {
  name_prefix = "${var.name_prefix}-workspace-"
  description = "Databricks Classic Compute plane communication"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name_prefix}-workspace" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "internal_tcp" {
  security_group_id            = aws_security_group.workspace.id
  referenced_security_group_id = aws_security_group.workspace.id
  description                  = "Databricks internal TCP communication"
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65535
}

resource "aws_vpc_security_group_ingress_rule" "internal_udp" {
  security_group_id            = aws_security_group.workspace.id
  referenced_security_group_id = aws_security_group.workspace.id
  description                  = "Databricks internal UDP communication"
  ip_protocol                  = "udp"
  from_port                    = 0
  to_port                      = 65535
}

resource "aws_vpc_security_group_egress_rule" "internal_tcp" {
  security_group_id            = aws_security_group.workspace.id
  referenced_security_group_id = aws_security_group.workspace.id
  description                  = "Databricks internal TCP communication"
  ip_protocol                  = "tcp"
  from_port                    = 0
  to_port                      = 65535
}

resource "aws_vpc_security_group_egress_rule" "internal_udp" {
  security_group_id            = aws_security_group.workspace.id
  referenced_security_group_id = aws_security_group.workspace.id
  description                  = "Databricks internal UDP communication"
  ip_protocol                  = "udp"
  from_port                    = 0
  to_port                      = 65535
}

locals {
  databricks_tcp_egress = {
    https                 = [443, 443]
    legacy_hive_metastore = [3306, 3306]
    lakebase              = [5432, 5432]
    control_plane         = [8443, 8451]
  }
}

resource "aws_vpc_security_group_egress_rule" "databricks_tcp" {
  for_each = local.databricks_tcp_egress

  security_group_id = aws_security_group.workspace.id
  description       = "Required Databricks outbound ${replace(each.key, "_", " ")} traffic"
  ip_protocol       = "tcp"
  from_port         = each.value[0]
  to_port           = each.value[1]
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_gateway_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(var.tags, { Name = "${var.name_prefix}-s3" })
}

data "aws_region" "current" {}
