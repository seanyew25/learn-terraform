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
  cidr_block = "10.0.0.0/16"
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

resource "aws_ami_from_instance" "copy_of_prod" {
  name               = "vue-project-copy"
  source_instance_id = data.aws_instances.prod_id.ids[0]
}

resource "aws_network_interface" "public_network" {
  subnet_id = aws_subnet.public_subnet.id
  private_ips = ["10.0.1.5"]
  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "vue-project" {
  ami = data.aws_ami.prod_ami.id
  instance_type = "t2.micro"
  tags = {
    Name = "vue-project-prod"
  }
  network_interface {
    network_interface_id = aws_network_interface.public_network.id
    device_index = 0
  }
}


resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.vue-project.id
  allocation_id = aws_eip.example.id
}
