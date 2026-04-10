# --- inference endpoint ---
# provisioned after pipeline completes and a model is approved in the registry
# run: make endpoint

resource "aws_sagemaker_model" "demo" {
  name               = "${var.prefix}-model"
  execution_role_arn = var.execution_role_arn

  primary_container {
    model_package_name = var.model_package_arn
  }

  vpc_config {
    subnets            = [var.subnet_id]
    security_group_ids = [var.security_group_id]
  }
}

resource "aws_sagemaker_endpoint_configuration" "demo" {
  name        = "${var.prefix}-endpoint-config"
  kms_key_arn = var.kms_key_arn

  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.demo.name
    initial_instance_count = 1
    instance_type          = var.endpoint_instance_type
    initial_variant_weight = 1.0
  }

  # capture 10% of requests for model monitoring
  data_capture_config {
    enable_capture              = true
    initial_sampling_percentage = 10
    destination_s3_uri          = "s3://${var.artifacts_bucket}/data-capture"

    capture_options {
      capture_mode = "Input"
    }

    capture_options {
      capture_mode = "Output"
    }
  }
}

resource "aws_sagemaker_endpoint" "demo" {
  name                 = "${var.prefix}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.demo.name

  tags = {
    Purpose = "secure-pipeline-inference"
  }
}

# --- auto-scaling ---
# scale-to-zero when idle — remediates COST-003
# minimum 0 instances, maximum 3

resource "aws_appautoscaling_target" "endpoint" {
  max_capacity       = 3
  min_capacity       = 0
  resource_id        = "endpoint/${aws_sagemaker_endpoint.demo.name}/variant/primary"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"
}

resource "aws_appautoscaling_policy" "scale_out" {
  name               = "${var.prefix}-scale-out"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.endpoint.resource_id
  scalable_dimension = aws_appautoscaling_target.endpoint.scalable_dimension
  service_namespace  = aws_appautoscaling_target.endpoint.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }
  }
}
