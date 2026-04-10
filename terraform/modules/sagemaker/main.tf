resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "demo" {
  name = "${var.prefix}-lifecycle"

  on_start = base64encode(<<-SCRIPT
    #!/bin/bash
    set -e

    sudo -u ec2-user -i <<'EOF'
    pip install --quiet shap matplotlib seaborn pandas scikit-learn \
      imbalanced-learn sagemaker --upgrade
    aws s3 cp s3://${var.training_bucket}/data/train.csv \
      /home/ec2-user/SageMaker/train.csv
    EOF
  SCRIPT
  )
}

# --- notebook instance ---
# runs inside the private subnet — no public IP
# kms_key_id encrypts the notebook volume

resource "aws_sagemaker_notebook_instance" "demo" {
  name          = "${var.prefix}-notebook"
  instance_type = "ml.t3.medium"
  role_arn      = var.execution_role_arn

  # VPC placement — remediates SEC-022
  subnet_id       = var.subnet_id
  security_groups = [var.security_group_id]

  # KMS encryption — remediates SEC-020
  kms_key_id = var.kms_key_arn

  lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_configuration.demo.name

  # start manually from console or via make run
  # avoids charges accumulating between demo sessions
  default_code_repository = null

  tags = {
    Purpose = "secure-pipeline-walkthrough"
  }
}

# --- model package group (registry) ---

resource "aws_sagemaker_model_package_group" "demo" {
  model_package_group_name        = "${var.prefix}-models"
  model_package_group_description = "Approved models from the ${var.prefix} pipeline"
}
