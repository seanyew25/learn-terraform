
# output "prod_id" {
#   description = "ID of the prod instance"
#   value       = data.aws_instance.prod_id
# }

# output "prod_ami" {
#   description = "ami of prod"
#   value       = data.aws_ami.prod_ami
# }

output "elastic_ip" {
  description = "eip"
  value       = data.aws_eips.elastic_ip
}

output "assume_role_vpc" {
  description = "assume role for vpc"
  value       = data.aws_iam_policy_document.assume_role_vpc.json
}