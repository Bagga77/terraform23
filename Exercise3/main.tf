module "vpc" {
  source = "./modules/vpc"
  total_subnets = 3
  client_name = "rmodule"
  env = "prod"
  vpc_cidr = "17.0.0.0/16"
}

module "ec2" {
  source = "./modules/ec2"
  ec2_type = "t2.micro"
  client_name = "rmodule"
  env = "prod"
  vpc_id = module.vpc.vpc_ID
  subnet_id = module.vpc.public_subnets[0]
}

module "rds" {
  source = "./modules/rds"
  client_name = "rmodule"
  env = "prod"
  subnet_ids = module.vpc.private_subnets
}
