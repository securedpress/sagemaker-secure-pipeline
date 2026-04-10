data "aws_caller_identity" "current" {}

resource "aws_kms_key" "main" {
  description             = "${var.prefix} — encryption key for S3 and SageMaker"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.kms_policy.json

  tags = {
    Name = "${var.prefix}-kms-key"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.prefix}"
  target_key_id = aws_kms_key.main.key_id
}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid    = "Enable IAM user permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow SageMaker service"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}
