locals {
  owner = "${var.client_name}-nclouds"
}

resource "aws_key_pair" "rbtkey" {
  key_name   = "rishav_o"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDAEFD4qFzU8HOcDUSZGbNlej/qmFDIeMHSvrIf6MQG6TDyZrTfWDfypwWywrAtudcfmz8T4We5NOeqkchLqqNZBU41BH91FQEr/sL/f2tmLb9vMBuM1savnXAVCRoH/TtrzISSAm0TWXFKK00TQK4O/QhYMml6A9CsMw12qYO5Mjn1lUiL5SILFtQI2KD8lFX9I2jDSIoYsYyY0fkJYGt/zDBbGlvrCtEWRq5lCEfKjHVHWDpI4393fZoIk6J0uNI2sOraj3D5Q/E7dJyERz38mMArgu+/TDJuP0jSaUO5D48EmdFPDtA2sFX/Z9pwWPpN12fl/HG+4gnEKXtnBrax"
}

resource "aws_eip" "rbtec2_ip" {
  domain = "vpc"
  tags = {
    Name = "${var.client_name}-${var.env}-ec2_eip"
    owner = local.owner
  }
}

resource "aws_security_group" "rbtssh" {
  name        = "${var.client_name}-${var.env}-ssh"
  description = "Allow ssh inbound traffic"
  vpc_id      = var.vpc_id

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
  subnet_id         = var.subnet_id
  key_name          = aws_key_pair.rbtkey.id
  vpc_security_group_ids = [aws_security_group.rbtssh.id]
    tags = {
    Name = "${var.client_name}-ec2"
    owner = local.owner
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.rbtec2.id
  allocation_id = aws_eip.rbtec2_ip.id
}