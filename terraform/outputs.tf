output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_id" {
  description = "Private subnet ID — SageMaker jobs run here"
  value       = module.vpc.private_subnet_id
}

output "kms_key_arn" {
  description = "KMS key ARN used for S3 and SageMaker encryption"
  value       = module.kms.key_arn
}

output "execution_role_arn" {
  description = "IAM execution role ARN for SageMaker"
  value       = module.iam.execution_role_arn
}

output "training_bucket" {
  description = "S3 training data bucket name"
  value       = module.s3.training_bucket_name
}

output "artifacts_bucket" {
  description = "S3 model artifacts bucket name"
  value       = module.s3.artifacts_bucket_name
}

output "model_package_group" {
  description = "SageMaker Model Package Group name"
  value       = module.sagemaker.model_package_group_name
}

output "pipeline_name" {
  description = "SageMaker Pipeline name"
  value       = local.pipeline_name
}
