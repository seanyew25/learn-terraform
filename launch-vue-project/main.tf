terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"

}


# create subnets in existing vpc

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "Vue Project Environment"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "Prod"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "Dev"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Vue Project IG"
  }
}

resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "2nd Route Table"
  }

}

resource "aws_route_table_association" "public_subnet_assoc" {
  route_table_id = aws_route_table.second_rt.id
  subnet_id      = aws_subnet.public_subnet.id
}


#Delete ami
# resource "aws_ami_from_instance" "copy_of_prod" {
#   name               = "vue-project-copy"
#   source_instance_id = data.aws_instance.prod_id.id
# }

resource "aws_network_interface" "public_network" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["10.0.1.5"]
  tags = {
    Name = "primary_network_interface"
  }
}


resource "aws_security_group" "security_group" {
  name        = "vue-project"
  description = "security group for vue-project"
  vpc_id      = aws_vpc.main.id

}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80

}
resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_postgres" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_egress_traffic" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.security_group.id
  network_interface_id = aws_network_interface.public_network.id
}

resource "aws_instance" "vue-project" {
  ami                         = data.aws_ami.prod_ami.id
  instance_type               = var.instance_type
  key_name                    = var.key-pair_name
  # associate_public_ip_address = true
  # security_groups             = var.security_groups

  tags = {
    Name = "vue-project-prod"
  }
  
  lifecycle {
    ignore_changes = [ami]
  }
  network_interface {
    network_interface_id = aws_network_interface.public_network.id
    device_index         = 0
  }
}


resource "aws_eip_association" "eip_assoc" {
  # instance_id   = aws_instance.vue-project.id
  network_interface_id = aws_network_interface.public_network.id
  allocation_id = data.aws_eips.elastic_ip.allocation_ids[0]
}


