# data "aws_instance" "prod_id" {
#   filter {
#     name   = "tag:Name"
#     values = ["vue-project"]
#   }
# }

# data "aws_ami" "prod_ami" {
#   # most_recent = true
#   filter {
#     name   = "name"
#     values = ["vue-project-copy"]
#   }
# }

data "aws_eips" "elastic_ip" {

}

data "aws_iam_policy_document" "assume_role_vpc" {
  statement {
    sid = "assume_role_vpc"
    actions   = ["execute-api:Invoke"]
    resources = [aws_api_gateway_rest_api.s3_api.execution_arn]

    principals {
      type        = "*"
      identifiers = [aws_vpc_endpoint.api_gw.id]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.api_gw.id]

    }
  }
}

data "aws_iam_role" "lambda_iam" {
  name = "lambda_role"
}

data "archive_file" "api_lambda_package" {
  type = "zip"
  source_file = "generateURL.py"
  output_path = "generateURL.zip"

}


