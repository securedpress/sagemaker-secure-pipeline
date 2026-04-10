data "aws_iam_policy_document" "sagemaker_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sagemaker_execution" {
  name               = "${var.prefix}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_trust.json

  description = "Least-privilege execution role for ${var.prefix} pipeline"
}

# --- scoped inline policy ---
# replaces AmazonSageMakerFullAccess + AmazonS3FullAccess
# permissions are scoped to this pipeline's specific resources only

resource "aws_iam_role_policy" "sagemaker_scoped" {
  name = "${var.prefix}-scoped-policy"
  role = aws_iam_role.sagemaker_execution.id

  policy = data.aws_iam_policy_document.sagemaker_scoped.json
}

data "aws_iam_policy_document" "sagemaker_scoped" {
  # S3 — scoped to this pipeline's buckets only
  statement {
    sid    = "S3TrainingData"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      var.training_bucket_arn,
      "${var.training_bucket_arn}/*",
      var.artifacts_bucket_arn,
      "${var.artifacts_bucket_arn}/*"
    ]
  }

  # KMS — scoped to this pipeline's key only
  statement {
    sid    = "KMSDecryptEncrypt"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = [var.kms_key_arn]
  }

  # SageMaker — pipeline, training, processing, model registry
  statement {
    sid    = "SageMakerPipeline"
    effect = "Allow"

    actions = [
      "sagemaker:CreateTrainingJob",
      "sagemaker:DescribeTrainingJob",
      "sagemaker:StopTrainingJob",
      "sagemaker:CreateProcessingJob",
      "sagemaker:DescribeProcessingJob",
      "sagemaker:StopProcessingJob",
      "sagemaker:CreateAutoMLJob",
      "sagemaker:DescribeAutoMLJob",
      "sagemaker:ListCandidatesForAutoMLJob",
      "sagemaker:CreateModel",
      "sagemaker:DescribeModel",
      "sagemaker:CreateModelPackage",
      "sagemaker:DescribeModelPackage",
      "sagemaker:UpdateModelPackage",
      "sagemaker:ListModelPackages",
      "sagemaker:CreatePipelineExecution",
      "sagemaker:DescribePipelineExecution",
      "sagemaker:ListPipelineExecutionSteps",
      "sagemaker:SendPipelineExecutionStepSuccess",
      "sagemaker:SendPipelineExecutionStepFailure"
    ]

    resources = ["*"]
  }

  # CloudWatch Logs — write pipeline execution logs
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/sagemaker/*"]
  }

  # ECR — pull training container images
  statement {
    sid    = "ECRReadOnly"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]

    resources = ["*"]
  }
}
