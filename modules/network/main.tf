resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.name}-vpc" }
}

data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # 10.0.0.0/16 reserved for public
  public_cidrs = [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24",
  ]

  db_private_cidrs = [
    "10.0.100.0/24",
    "10.0.101.0/24",
    "10.0.102.0/24",
  ]

  ecs_private_cidrs = [
    "10.0.200.0/24",
    "10.0.201.0/24",
    "10.0.202.0/24",
  ]
}

# Internet Gateway & public route table
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
  depends_on = [ aws_nat_gateway.nat ]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Public subnets + associations
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "${var.name}-public-${count.index}" }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT + private route tables per AZ
resource "aws_eip" "nat" {
  count  = var.az_count
  domain = "vpc"
  tags   = { Name = "${var.name}-nat-eip-${count.index}" }
}

resource "aws_nat_gateway" "nat" {
  count         = var.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "${var.name}-nat-${count.index}" }
}

# DB subnets (isolated)
resource "aws_subnet" "db" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.db_private_cidrs[count.index]
  availability_zone = local.azs[count.index]
  tags = { Name = "${var.name}-db-${count.index}" }
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-rt-db" }
}

resource "aws_route_table_association" "db" {
  count          = var.az_count
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}

# ECS subnets (NAT-routed)
resource "aws_subnet" "ecs" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.ecs_private_cidrs[count.index]
  availability_zone = local.azs[count.index]
  tags = { Name = "${var.name}-ecs-${count.index}" }
}

resource "aws_route_table" "ecs" {
  count  = var.az_count
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = { Name = "${var.name}-rt-ecs-${count.index}" }
}

resource "aws_route_table_association" "ecs" {
  count          = var.az_count
  subnet_id      = aws_subnet.ecs[count.index].id
  route_table_id = aws_route_table.ecs[count.index].id
}
