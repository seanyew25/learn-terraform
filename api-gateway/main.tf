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

resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "Books"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ID"
  range_key      = "BookTitle"

  attribute {
    name = "ID"
    type = "N"
  }

  attribute {
    name = "BookTitle"
    type = "S"
  }

  attribute {
    name = "Author"
    type = "S"
  }



    global_secondary_index {
    name               = "AuthorIndex"
    hash_key           = "Author"
    write_capacity     = 5
    read_capacity      = 5
    projection_type    = "INCLUDE"
    non_key_attributes = ["BookTitle"]
  }

  provisioner "local-exec" {
    command = "bash populate_db.sh"
  }

  tags = {
    Name = "dynamo-table-1"
  }


}
