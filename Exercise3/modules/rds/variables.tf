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

variable "subnet_ids" {
  type = list(string)
  description = "List of available private subnet ids"
}