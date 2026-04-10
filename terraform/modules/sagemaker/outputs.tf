output "notebook_name" {
  value = aws_sagemaker_notebook_instance.demo.name
}

output "model_package_group_name" {
  value = aws_sagemaker_model_package_group.demo.model_package_group_name
}
