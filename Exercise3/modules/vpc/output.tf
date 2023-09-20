output "vpc_ID" {
  value = aws_vpc.rbtvpc.id
  description = "VPC ID By Terraform"
}

output "public_subnets" {
  value = aws_subnet.public.*.id
  description = "List of Public Subnet"
}

output "private_subnets" {
  value = aws_subnet.private.*.id
  description = "List of Public Subnet" 
}

output "az" {
  value = data.aws_availability_zones.available.names
}

output "az_counts" {
  value = length(data.aws_availability_zones.available.names)
}