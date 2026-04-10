output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "sagemaker_sg_id" {
  value = aws_security_group.sagemaker.id
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}
