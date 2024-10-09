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

# create lambda role
resource "aws_iam_role" "lambda_iam" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

# create policy for lambda to access dynamo db
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

# attach policy to lambda role
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

resource "aws_lambda_function" "books_lambda" {

  filename = "booksLambdaFunction.zip"

  function_name = "getBooks"

  role = aws_iam_role.lambda_iam.arn

  handler = "booksLambdaFunction.lambda_handler"

  runtime = "python3.9"

  source_code_hash = data.archive_file.api_lambda_package.output_base64sha256

}

# api role
# resource "aws_iam_role" "api_role" {
#   name               = "api_role"
#   assume_role_policy = data.aws_iam_policy_document.assume_role_api.json
# }

# permission for lambda to access api
resource "aws_iam_role_policy_attachment" "access_api_policy" {
  role       = aws_iam_role.lambda_iam.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#permission for api gateway to access lambda
resource "aws_lambda_permission" "apigw_lambda" {

  statement_id = "AllowExecutionFromAPIGateway"

  action = "lambda:InvokeFunction"

  function_name = aws_lambda_function.books_lambda.function_name

  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.books_api.execution_arn}/*/*"

}
resource "aws_api_gateway_resource" "books_root" {

  rest_api_id = aws_api_gateway_rest_api.books_api.id

  parent_id = aws_api_gateway_rest_api.books_api.root_resource_id

  path_part = "books"

}

# resource "aws_api_gateway_method" "post_method" {

#   rest_api_id = aws_api_gateway_rest_api.books_api.id

#   resource_id = aws_api_gateway_resource.books_root.id

#   http_method = "POST"

#   authorization = "NONE"

# }

resource "aws_api_gateway_method" "get_method" {

  rest_api_id = aws_api_gateway_rest_api.books_api.id

  resource_id = aws_api_gateway_resource.books_root.id

  http_method = "ANY"

  authorization = "NONE"

}

resource "aws_api_gateway_integration" "api_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.books_api.id
  type                    = "AWS_PROXY"
  resource_id             = aws_api_gateway_resource.books_root.id
  http_method             = aws_api_gateway_method.get_method.http_method
  uri                     = aws_lambda_function.books_lambda.invoke_arn
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "books_deployment" {
  # depends_on = [

  # aws_api_gateway_integration.lambda_integration,

  # aws_api_gateway_integration.options_integration, # Add this line

  # ]
  rest_api_id = aws_api_gateway_rest_api.books_api.id
  stage_name  = "dev"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.books_root.id,
      aws_api_gateway_method.get_method.id,
      aws_api_gateway_integration.api_lambda.id,
    ]))
  }
}

resource "aws_api_gateway_method_response" "proxy" {

  rest_api_id = aws_api_gateway_rest_api.books_api.id

  resource_id = aws_api_gateway_resource.books_root.id

  http_method = aws_api_gateway_method.get_method.http_method

  status_code = "200"



  //cors section

  response_parameters = {

    "method.response.header.Access-Control-Allow-Headers" = true,

    "method.response.header.Access-Control-Allow-Methods" = true,

    "method.response.header.Access-Control-Allow-Origin" = true

  }



}



resource "aws_api_gateway_integration_response" "proxy" {

  rest_api_id = aws_api_gateway_rest_api.books_api.id

  resource_id = aws_api_gateway_resource.books_root.id

  http_method = aws_api_gateway_method.get_method.http_method

  status_code = aws_api_gateway_method_response.proxy.status_code





  //cors

  response_parameters = {

    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",

    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",

    "method.response.header.Access-Control-Allow-Origin" = "'*'"

  }



  depends_on = [

    aws_api_gateway_method.get_method,

    aws_api_gateway_integration.api_lambda

  ]

}
