variable "client_name" {
  type = string
  description = "This will be included in all resource names terraform create"
  default = "rishav"
}

variable "env" {
  type = string
  description = "This Environment Name will be included in all resource names terraform create"
  default = "prod"       #it will not ask for input its value if we provide default
  #we can provide value instead of default using this command:- terraform apply -var="env=prod"
}

variable "ec2_type" {
  type = string
  description = "EC2 Instance Type"
  default = "t2.micro"
}

variable "vpc_id" {
  type = string
  description = "vpcID"
}

variable "subnet_id" {
  type = string
  description = "public subnet ID"
}