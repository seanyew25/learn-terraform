data "aws_instances" "prod_id" {
  instance_state_names = ["running"]
}

data "aws_ami" "prod_ami" {
    most_recent = true
}

data "aws_eips" "elastic_ip"{
    
}