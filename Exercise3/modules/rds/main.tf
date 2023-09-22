locals {
  owner = "${var.client_name}-nclouds"
}

resource "aws_db_subnet_group" "rtsubgroup" {
  name       = "main"
  subnet_ids = var.subnet_ids
  tags = {
    Name = "My ${var.client_name}-DB subnet group"
    owner = local.owner
  }
}

resource "aws_db_instance" "rbtrds" {
  count                = var.env == "prod" ? 1 : 0
  identifier           = "${var.client_name}-${var.env}-rds"
  allocated_storage    = var.env == "dev" ? 20 : 50
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