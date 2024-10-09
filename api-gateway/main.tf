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

resource "aws_iam_role" "lambda_iam" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "manage_dynamo_db" {
  name        = "manage_dynamo_db"
  path        = "/"
  description = "manage_dynamo_db"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ReadWriteTable",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:BatchGetItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Resource" : "arn:aws:dynamodb:*:*:table/Books"
      },
    ]

  })
}

resource "aws_iam_role_policy_attachment" "manage_dynamo_db_policy" {
  role       = aws_iam_role.lambda_iam.name
  policy_arn = aws_iam_policy.manage_dynamo_db.arn
}


resource "aws_api_gateway_rest_api" "books_api" {

  name = "my-api"

  description = "My API Gateway"



  endpoint_configuration {

    types = ["REGIONAL"]

  }

}

resource "aws_api_gateway_resource" "root" {

  rest_api_id = aws_api_gateway_rest_api.books_api.id

  parent_id = aws_api_gateway_rest_api.books_api.root_resource_id

  path_part = "books"

}

resource "aws_api_gateway_method" "proxy" {

  rest_api_id = aws_api_gateway_rest_api.my_api.id

  resource_id = aws_api_gateway_resource.root.id

  http_method = "POST"

  authorization = "NONE"

}
