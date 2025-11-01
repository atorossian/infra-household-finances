# modules/network/main.tf

data "aws_availability_zones" "this" {
  state = "available"
}

locals {
  # limit AZs to requested count
  az_names = slice(data.aws_availability_zones.this.names, 0, var.az_count)

  # carve subnets out of the VPC CIDR
  # public:  cidrsubnet(vpc, newbits=8, index=0..)
  # private: cidrsubnet(vpc, newbits=8, index=100..)
  public_subnet_cidrs  = [for i in range(length(local.az_names)) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnet_cidrs = [for i in range(length(local.az_names)) : cidrsubnet(var.vpc_cidr, 8, 100 + i)]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.name_prefix}-vpc"
    Environment = "dev"
    Project     = "household-finances"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# -----------------------------
# PUBLIC SUBNETS + ROUTING
# -----------------------------
resource "aws_subnet" "public" {
  for_each = { for idx, az in local.az_names : idx => { az = az, cidr = local.public_subnet_cidrs[idx] } }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------
# NAT (CONDITIONAL TO AVOID COST)
# -----------------------------
# Create these only when var.create_nat_gateway = true
resource "aws_eip" "nat" {
  count  = var.create_nat_gateway ? 1 : 0
  domain = "vpc"
  tags   = { Name = "${var.name_prefix}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  count         = var.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public["0"].id
  tags          = { Name = "${var.name_prefix}-nat" }
  depends_on    = [aws_internet_gateway.this]
}

# -----------------------------
# PRIVATE SUBNETS + ROUTING
# -----------------------------
resource "aws_subnet" "private" {
  for_each = { for idx, az in local.az_names : idx => { az = az, cidr = local.private_subnet_cidrs[idx] } }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${var.name_prefix}-private-${each.key}"
    Tier = "private"
  }
}

# one private route table for all private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.name_prefix}-private-rt"
  }
}

# Default route from private subnets to NAT — only when NAT exists
resource "aws_route" "private_to_nat" {
  count                  = var.create_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
