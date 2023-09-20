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

variable "vpc_cidr" {
  type = string
  description = "CIDR Block for VPC"
  default = "17.0.0.0/16"
}

variable "total_subnets" {
  type = string
  description = "Enter number of Subnets needed each for private and public"
}