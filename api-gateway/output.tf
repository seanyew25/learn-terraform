# output "iam_role" {
#   value = data.aws_iam_policy_document.assume_role
# }

output "api_url" {
  value = aws_api_gateway_deployment.books_deployment.invoke_url
}

output "http_method" {
  value = aws_api_gateway_method.root_method.http_method
}