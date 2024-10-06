output "iam_role" {
  value = data.aws_iam_policy_document.assume_role
}