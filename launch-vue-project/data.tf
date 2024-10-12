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
    effect = "Allow"
    sid = "assume_role_vpc"
    actions   = ["execute-api:Invoke"]
    resources = [format("%s/*", aws_api_gateway_rest_api.s3_api.execution_arn)]

    principals {
      type        = "*"
      identifiers = [aws_vpc_endpoint.api_gw.id]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpc"
      values   = [aws_vpc.main.id]

    }
  }
}

data "aws_iam_role" "lambda_iam" {
  name = "lambda_role"
}

data "aws_iam_role" "api_iam" {
  name = "api_role"
}

data "archive_file" "api_lambda_package" {
  type = "zip"
  source_file = "generateURL.py"
  output_path = "generateURL.zip"

}


