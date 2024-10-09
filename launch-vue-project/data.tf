data "aws_instance" "prod_id" {
  filter {
    name   = "tag:Name"
    values = ["vue-project"]
  }
}

data "aws_ami" "prod_ami" {
  # most_recent = true
  filter {
    name   = "name"
    values = ["vue-project-copy"]
  }
}

data "aws_eips" "elastic_ip" {

}



