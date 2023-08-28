terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "tf-rt"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "RTdynamo"
  }
}

provider "aws" {
  region = "us-west-2"
  profile = "nclouds-support"
}

resource "aws_vpc" "rtvpc" {
  cidr_block = "12.0.0.0/16"
  tags = {
    Name = "rtvpc"
  }
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.rtvpc.id
  cidr_block = "12.0.1.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "rt public 1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id     = aws_vpc.rtvpc.id
  cidr_block = "12.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "rt public 2"
  }
}

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.rtvpc.id
  cidr_block = "12.0.3.0/24"
  availability_zone = "us-west-2a"
  tags = {
    Name = "rt private 1"
  }
}

resource "aws_subnet" "private2" {
  vpc_id     = aws_vpc.rtvpc.id
  cidr_block = "12.0.4.0/24"
  availability_zone = "us-west-2b"  

  tags = {
    Name = "rt private 2"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.rtvpc.id

  tags = {
    Name = "rtIGW"
  }
}

resource "aws_eip" "rtnat_ip" {
  domain = "vpc"

  tags = {
    Name = "rteip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.rtnat_ip.id
  subnet_id     = aws_subnet.public2.id

  tags = {
    Name = "rtNATgw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.rtvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public rt"
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.rtvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private rt"
  }
}

resource "aws_route_table_association" "a3" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "a4" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_key_pair" "rtkey" {
  key_name   = "rishav_o"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKR2UZu+fVDACozoUbYd4bofV7h0QAVezmYAtdrdMhKL2D52veU8F+7Smp3PzPCVE0lBQ9m524VJ8QF7PFkScgE3UgIpgGmrX2SgTt9hVz6QUmBBAUVCAjUSr+fLcYLQQTPhuO2WtKksfpG/M4gSHwliHCDpv908W5iq3luS4fU6Jruk4plYZJyvxkh4VRKO3K0Sh9FYBZa911/+xEvMx48MiaHKvnMdOIreGWGiEMTzY4xUCQadob1T+FUkSrnmYFhTrGJROKMFdxb4Pv/HM0F8/HmdtoX+YRlHn71a5WqwhErOpzg8r65EAgQGjG1SQawyfvQ4zzPvwDNFwv9OkZ"
}

resource "aws_eip" "rtec2_ip" {
  domain = "vpc"

  tags = {
    Name = "rtec2_eip"
  }
}

resource "aws_security_group" "rtssh" {
  name        = "rtssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.rtvpc.id

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
    Name = "rt_ssh"
  }
}

resource "aws_instance" "rtec2" {
  ami               = "ami-03f65b8614a860c29"
  instance_type     = "t2.micro"
  subnet_id         = aws_subnet.public1.id
  key_name          = aws_key_pair.rtkey.id
  vpc_security_group_ids = [aws_security_group.rtssh.id]
  
  tags = {
    Name = "rtec2"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.rtec2.id
  allocation_id = aws_eip.rtec2_ip.id
}

resource "aws_db_subnet_group" "rtsubgroup" {
  name       = "main"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]

  tags = {
    Name = "My RT DB subnet group"
  }
}

resource "aws_db_instance" "rtrds" {
  identifier             = "rtrds"
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
    Name = "rtRDS"
  }
}