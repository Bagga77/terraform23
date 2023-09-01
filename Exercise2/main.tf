data "aws_iam_account_alias" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

output "az" {
  value = data.aws_availability_zones.available.all_availability_zones
}

locals {
  owner = "${var.client_name}-nclouds"
  account_id = data.aws_iam_account_alias.current.id
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
  vpc_id     = aws_vpc.rbtvpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = data.aws_availability_zones.available.all_availability_zones
  tags = {
    Name = "${var.client_name}-${var.env}-public"
    owner = local.owner
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.rbtvpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone = data.aws_availability_zones.available.all_availability_zones
  tags = {
    Name = "${var.client_name}-${var.env}-private"
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
  subnet_id     = aws_subnet.public.id

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
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rbt.id
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

resource "aws_route_table_association" "a3" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rbt.id
}

resource "aws_key_pair" "rbtkey" {
  key_name   = "rishav_o"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKR2UZu+fVDACozoUbYd4bofV7h0QAVezmYAtdrdMhKL2D52veU8F+7Smp3PzPCVE0lBQ9m524VJ8QF7PFkScgE3UgIpgGmrX2SgTt9hVz6QUmBBAUVCAjUSr+fLcYLQQTPhuO2WtKksfpG/M4gSHwliHCDpv908W5iq3luS4fU6Jruk4plYZJyvxkh4VRKO3K0Sh9FYBZa911/+xEvMx48MiaHKvnMdOIreGWGiEMTzY4xUCQadob1T+FUkSrnmYFhTrGJROKMFdxb4Pv/HM0F8/HmdtoX+YRlHn71a5WqwhErOpzg8r65EAgQGjG1SQawyfvQ4zzPvwDNFwv9OkZ"
}

resource "aws_eip" "rbtec2_ip" {
  domain = "vpc"

  tags = {
    Name = "${var.client_name}--${var.env}ec2_eip"
    owner = local.owner
  }
}

resource "aws_security_group" "rbtssh" {
  name        = "${var.client_name}-${var.env}-ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.rbtvpc.id

  ingress {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  ingress {
      description      = "HTTPS from VPC"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  ingress {
      description      = "HTTP from VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.client_name}-${var.env}-ssh"
    owner = local.owner
  }
}

resource "aws_instance" "rbtec2" {
  ami               = "ami-03f65b8614a860c29"
  instance_type     = var.ec2_type
  subnet_id         = aws_subnet.public.id
  key_name          = aws_key_pair.rbtkey.id
  vpc_security_group_ids = [aws_security_group.rbtssh.id]
    tags = {
    Name = "${var.client_name}-ec2"
    owner = local.owner
  }
}

output "ec2hostid" {
  value = "aws_instance.rbtec2.host_id"
  description = "Instance ID"
  depends_on = [ aws_instance.rbtec2 ]
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.rbtec2.id
  allocation_id = aws_eip.rbtec2_ip.id
}

resource "aws_db_subnet_group" "rtsubgroup" {
  name       = "main"
  subnet_ids = [aws_subnet.private.id]

  tags = {
    Name = "My ${var.client_name}-DB subnet group"
    owner = local.owner
  }
}

resource "aws_db_instance" "rbtrds" {
  identifier             = "${var.client_name}-${var.env}-rds"
  allocated_storage    = 20
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "5.7"
  db_subnet_group_name = aws_db_subnet_group.rtsubgroup.name
  instance_class       = "db.t3.small"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true

    tags = {
    Name = "${var.client_name}-RDS"
    owner = local.owner
  }
}