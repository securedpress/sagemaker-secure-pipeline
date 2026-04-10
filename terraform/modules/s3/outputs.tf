output "training_bucket_name" {
  value = aws_s3_bucket.training_data.bucket
}

output "training_bucket_arn" {
  value = aws_s3_bucket.training_data.arn
}

output "artifacts_bucket_name" {
  value = aws_s3_bucket.model_artifacts.bucket
}

output "artifacts_bucket_arn" {
  value = aws_s3_bucket.model_artifacts.arn
}
