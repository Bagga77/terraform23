data "aws_iam_account_alias" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  owner = "${var.client_name}-nclouds"
  account_id = data.aws_iam_account_alias.current.id
  subnetcount = "${var.total_subnets}" != "0" ? "${var.total_subnets}" : "${length(data.aws_availability_zones.available.names)}"
}

resource "aws_vpc" "rbtvpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.client_name}-${var.env}-vpc"
    owner = local.owner
    account = local.account_id
  }
}

resource "aws_subnet" "public" {
  count      = local.subnetcount
  #count      = var.total_subnets
  vpc_id     = aws_vpc.rbtvpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  tags = {
    Name = "${var.client_name}-${var.env}-public-${count.index}"
    owner = local.owner
  }
} 

resource "aws_subnet" "private" {
  count      = local.subnetcount
  #count      = var.total_subnets
  vpc_id     = aws_vpc.rbtvpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index + local.subnetcount)
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  tags = {
    Name = "${var.client_name}-${var.env}-private-${count.index}"
    owner = local.owner
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.rbtvpc.id

  tags = {
    Name = "${var.client_name}-${var.env}-IGW"
    owner = local.owner
  }
}

resource "aws_eip" "rbtnat_ip" {
  domain = "vpc"

  tags = {
    Name = "${var.client_name}-${var.env}-eip"
    owner = local.owner
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.rbtnat_ip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.client_name}-${var.env}-NATgw"
    owner = local.owner
  }
}

resource "aws_route_table" "public_rbt" {
  vpc_id = aws_vpc.rbtvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.client_name}-${var.env}-public_rt"
    owner = local.owner
  }
}

resource "aws_route_table_association" "a1" {
  count      = local.subnetcount
  #count      = var.total_subnets
  depends_on     = [ aws_subnet.public ]
  route_table_id = aws_route_table.public_rbt.id
  subnet_id      = aws_subnet.public[count.index].id
  
}

resource "aws_route_table" "private_rbt" {
  vpc_id = aws_vpc.rbtvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.client_name}-${var.env}-private-rt"
    owner = local.owner
  }
}

resource "aws_route_table_association" "a2" {
  count      = local.subnetcount
  #count      = var.total_subnets
  depends_on     = [ aws_subnet.private ]
  route_table_id = aws_route_table.private_rbt.id
  subnet_id      = aws_subnet.private[count.index].id
}