
output "ec2hostid" {
  value = aws_instance.rbtec2.host_id
  description = "Instance ID"
  depends_on = [ aws_instance.rbtec2 ]
}