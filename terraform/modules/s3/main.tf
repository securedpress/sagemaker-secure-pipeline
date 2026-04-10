data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "training_data" {
  bucket        = "${var.prefix}-training-data"
  force_destroy = true
}

resource "aws_s3_bucket" "model_artifacts" {
  bucket        = "${var.prefix}-model-artifacts"
  force_destroy = true
}

# --- versioning ---

resource "aws_s3_bucket_versioning" "training_data" {
  bucket = aws_s3_bucket.training_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "model_artifacts" {
  bucket = aws_s3_bucket.model_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- KMS encryption (customer-managed key) ---
# replaces AES256 from sagemaker-autopilot-demo — remediates SEC-020

resource "aws_s3_bucket_server_side_encryption_configuration" "training_data" {
  bucket = aws_s3_bucket.training_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "model_artifacts" {
  bucket = aws_s3_bucket.model_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# --- block all public access ---

resource "aws_s3_bucket_public_access_block" "training_data" {
  bucket                  = aws_s3_bucket.training_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "model_artifacts" {
  bucket                  = aws_s3_bucket.model_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- bucket policies enforcing VPC endpoint access ---
# denies all S3 access that does not originate from the VPC endpoint
# this ensures training data never traverses the public internet

resource "aws_s3_bucket_policy" "training_data" {
  bucket = aws_s3_bucket.training_data.id
  policy = data.aws_iam_policy_document.training_data_policy.json

  depends_on = [aws_s3_bucket_public_access_block.training_data]
}

data "aws_iam_policy_document" "training_data_policy" {
  statement {
    sid    = "DenyNonVPCEndpointAccess"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.training_data.arn,
      "${aws_s3_bucket.training_data.arn}/*"
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"
      values   = [var.vpc_endpoint_id]
    }

    # allow terraform and CI/CD to manage the bucket from outside the VPC
    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_s3_bucket_policy" "model_artifacts" {
  bucket = aws_s3_bucket.model_artifacts.id
  policy = data.aws_iam_policy_document.model_artifacts_policy.json

  depends_on = [aws_s3_bucket_public_access_block.model_artifacts]
}

data "aws_iam_policy_document" "model_artifacts_policy" {
  statement {
    sid    = "DenyNonVPCEndpointAccess"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.model_artifacts.arn,
      "${aws_s3_bucket.model_artifacts.arn}/*"
    ]

    condition {
      test     = "StringNotEquals"
      variable = "aws:sourceVpce"
      values   = [var.vpc_endpoint_id]
    }

    condition {
      test     = "ArnNotLike"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}
