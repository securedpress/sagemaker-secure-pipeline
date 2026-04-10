output "execution_role_arn" {
  value = aws_iam_role.sagemaker_execution.arn
}

output "execution_role_name" {
  value = aws_iam_role.sagemaker_execution.name
}
