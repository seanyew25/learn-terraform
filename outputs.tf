
output "prod_id" {
  description = "ID of the prod instance"
  value       = data.aws_instances.prod_id
}

output "prod_ami" {
    description = "ami of prod"
    value = data.aws_ami.prod_ami
}

output "elastic_ip" {
    description = "eip"
    value = data.aws_eips.elastic_ip
}