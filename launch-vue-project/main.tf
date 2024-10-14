terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.57.0"
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
  # enable communicatiion between public subnet and internet
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  # enable communication between public subnet and private subnet
  # route {
  #   cidr_block = "10.0.2.0/24"
  #   # vpc_endpoint_id = aws_vpc_endpoint.api_gw.id
  #   network_interface_id = "eni-01f3c613e37f585cc"
  # }
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
  ami           = "ami-0e8fa92930184a871"
  instance_type = var.instance_type
  key_name      = var.key-pair_name
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
  allocation_id        = data.aws_eips.elastic_ip.allocation_ids[0]
}

# resource "aws_security_group" "vpc_endpoint" {
#   name        = "endpoint"
#   description = "security group for vpc endpoint"
#   vpc_id      = aws_vpc.main.id

# }

# resource "aws_vpc_security_group_ingress_rule" "endpoint_allow_https" {
#   security_group_id = aws_security_group.vpc_endpoint.id
#   from_port         = 443
#   to_port           = 443
#   ip_protocol       = "tcp"
#   cidr_ipv4         = "0.0.0.0/0"
# }

# resource "aws_vpc_security_group_ingress_rule" "endpoint_allow_http" {
#   security_group_id = aws_security_group.vpc_endpoint.id
#   from_port         = 80
#   to_port           = 80
#   ip_protocol       = "tcp"
#   cidr_ipv4         = "0.0.0.0/0"
# }

# resource "aws_vpc_security_group_egress_rule" "endpoint_allow_all_egress_traffic" {
#   security_group_id = aws_security_group.vpc_endpoint.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

# resource "aws_vpc_endpoint" "api_gw" {
#   vpc_id            = aws_vpc.main.id
#   service_name      = "com.amazonaws.ap-southeast-1.execute-api"
#   vpc_endpoint_type = "Interface"
#   private_dns_enabled = true
#   tags = {
#     Name = "api-gateway"
#   }
#   subnet_configuration {
#     ipv4      = "10.0.2.10"
#     subnet_id = aws_subnet.private_subnet.id
#   }
#   subnet_ids         = [aws_subnet.private_subnet.id]
#   security_group_ids = [aws_security_group.vpc_endpoint.id]

# }

# resource "aws_api_gateway_rest_api" "s3_api" {
#   name = "s3-api"
#   description = "api to create pre-signed urls with s3"

#   endpoint_configuration {
#     types            = ["PRIVATE"]
#     vpc_endpoint_ids = [aws_vpc_endpoint.api_gw.id]
#   }

# }

# resource "aws_api_gateway_resource" "s3_resource" {
#   parent_id   = aws_api_gateway_rest_api.s3_api.root_resource_id
#   path_part   = "img"
#   rest_api_id = aws_api_gateway_rest_api.s3_api.id
# }

# resource "aws_api_gateway_method" "s3" {
#   authorization = "NONE"
#   http_method   = "ANY"
#   resource_id   = aws_api_gateway_resource.s3_resource.id
#   rest_api_id   = aws_api_gateway_rest_api.s3_api.id
# }

# # create resource policy for vpc to access this api and to deny all others access to it
# resource "aws_api_gateway_rest_api_policy" "rest_api" {
#   rest_api_id = aws_api_gateway_rest_api.s3_api.id
#   policy      = jsonencode({    
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Deny",
#             "Principal": "*",
#             "Action": "execute-api:Invoke",
#             "Resource": "execute-api:/*",
#             "Condition": {
#                 "StringNotEquals": {
#                     "aws:sourceVpce": "${aws_vpc_endpoint.api_gw.id}"
#                 }
#             }
#         },
#         {
#             "Effect": "Allow",
#             "Principal": "*",
#             "Action": "execute-api:Invoke",
#             "Resource": "execute-api:/*"
#         }
#      ]
#   })
# }

resource "aws_s3_bucket" "img-storage" {
  bucket = "img-storage"

  tags = {
    Name = "website_img_storage"
  }
}
# resource "aws_iam_policy" "crud_s3" {
#   name = "crud_s3"
#   path = "/"
#   description = "policy to allow crud operations on s3"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement: [
#       {
#         Effect: "Allow",
#         Action: [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject"
#         ],
#         Resource: [
#           "${aws_s3_bucket.img-storage.arn}/*"
#         ]
#       }
#     ]
#   })

# }
# resource "aws_iam_role_policy_attachment" "attach_to_s3" {
#   role = data.aws_iam_role.lambda_iam.name
#   policy_arn = aws_iam_policy.crud_s3.arn
# }

# resource "aws_lambda_function" "img_lambda" {
#   filename      = "generateURL.zip"
#   function_name = "generateURL"
#   role          = data.aws_iam_role.lambda_iam.arn
#   handler = "generateURL.lambda_handler"
#   runtime = "python3.9"
#   source_code_hash = data.archive_file.api_lambda_package.output_base64sha256
# }

# resource "aws_api_gateway_integration" "api_lambda" {
#   rest_api_id             = aws_api_gateway_rest_api.s3_api.id
#   type                    = "AWS_PROXY"
#   resource_id             = aws_api_gateway_resource.s3_resource.id
#   http_method             = aws_api_gateway_method.s3.http_method
#   uri                     = aws_lambda_function.img_lambda.invoke_arn
#   integration_http_method = "POST"
# }

# resource "aws_api_gateway_method_response" "proxy" {

#   rest_api_id = aws_api_gateway_rest_api.s3_api.id

#   resource_id = aws_api_gateway_resource.s3_resource.id

#   http_method = aws_api_gateway_method.s3.http_method

#   status_code = "200"



#   //cors section

#   response_parameters = {

#     "method.response.header.Access-Control-Allow-Headers" = true,

#     "method.response.header.Access-Control-Allow-Methods" = true,

#     "method.response.header.Access-Control-Allow-Origin" = true

#   }

# }


# resource "aws_api_gateway_deployment" "s3_api" {
#   rest_api_id = aws_api_gateway_rest_api.s3_api.id
#   # stage_name = "dev"
#   triggers = {
#     redeployment = sha1(jsonencode([
#       aws_api_gateway_method.s3.id,
#       aws_api_gateway_resource.s3_resource.id,
#       data.aws_iam_policy_document.assume_role_vpc.json
#     ]))
#   }
# }

# resource "aws_api_gateway_stage" "s3_api_stage" {
#   deployment_id = aws_api_gateway_deployment.s3_api.id
#   rest_api_id   = aws_api_gateway_rest_api.s3_api.id
#   stage_name    = "dev"
#   lifecycle {
#     replace_triggered_by = [ aws_api_gateway_deployment.s3_api ]
#   }
# }

# resource "aws_api_gateway_method_settings" "logging" {
#   rest_api_id = aws_api_gateway_rest_api.s3_api.id
#   stage_name  = aws_api_gateway_stage.s3_api_stage.stage_name
#   method_path = "*/*"

#   settings {
#     metrics_enabled = true
#     logging_level   = "INFO"
#     data_trace_enabled = true
#   }
# }

# resource "aws_iam_role_policy_attachment" "api_logging_permissions" {
#   role       = data.aws_iam_role.api_iam.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs" 
# }

# resource "aws_iam_policy" "log_perm" {
#   name = "logging_to_cloudfront"
#   path = "/"
#   description = "policy to allow logging"

#   policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Action": [
#                 "logs:CreateLogGroup",
#                 "logs:CreateLogStream",
#                 "logs:PutLogEvents"
#             ],
#             "Resource": "*"
#         }
#     ]
#   })

# }

# resource "aws_iam_role_policy_attachment" "attach_to_api" {
#   role = data.aws_iam_role.api_iam.name
#   policy_arn = aws_iam_policy.log_perm.arn
# }

# # tell api gateway to use this role for logging
# resource "aws_api_gateway_account" "s3_api" {
#   cloudwatch_role_arn = data.aws_iam_role.api_iam.arn
# }

# resource "aws_cloudwatch_log_group" "s3_api" {
#   name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.s3_api.id}/${aws_api_gateway_method_settings.logging.stage_name}"
#   retention_in_days = 7
#   tags = {
#     Name = "API-Gateway-Execution-Logs"
#   }
# }

# resource "aws_lambda_permission" "apigw_lambda" {

#   statement_id = "AllowExecutionFromAPIGateway"

#   action = "lambda:InvokeFunction"

#   function_name = aws_lambda_function.img_lambda.function_name

#   principal = "apigateway.amazonaws.com"

#   source_arn = "${aws_api_gateway_rest_api.s3_api.execution_arn}/*"

# }