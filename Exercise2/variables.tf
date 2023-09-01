variable "client_name" {
  type = string
  description = "This will be included in all resource names terraform create"
}

variable "env" {
  type = string
  description = "This Environment Name will be included in all resource names terraform create"
  default = "dev"       #it will not ask for input its value if we provide default
  #we can provide value instead of default using this command:- terraform apply -var="env=prod"
}
variable "ec2_type" {
  type = string
  description = "EC2 Instance Type"
}

variable "vpc_cidr" {
  type = string
  description = "CIDR Block for VPC"
  default = "17.0.0.0/16"
}