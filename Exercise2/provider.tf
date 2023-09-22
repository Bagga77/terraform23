terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "tf-rbt"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "RBTdynamo"
  }
}

provider "aws" {
  region = "us-west-2"
  profile = "training"
}