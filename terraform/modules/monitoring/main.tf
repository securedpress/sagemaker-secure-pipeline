locals {
  alarm_prefix = "${var.prefix}-alarm"
}

# --- 5XX error alarm ---

resource "aws_cloudwatch_metric_alarm" "endpoint_5xx_errors" {
  alarm_name  = "${local.alarm_prefix}-5xx-errors"
  namespace   = "AWS/SageMaker"
  metric_name = "Invocation5XXErrors"

  dimensions = {
    EndpointName = var.endpoint_name
    VariantName  = "primary"
  }

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_description = "${var.endpoint_name} is returning 5XX errors — model serving may be unhealthy"
}

# --- p99 latency alarm ---

resource "aws_cloudwatch_metric_alarm" "endpoint_latency_p99" {
  alarm_name  = "${local.alarm_prefix}-latency-p99"
  namespace   = "AWS/SageMaker"
  metric_name = "ModelLatency"

  dimensions = {
    EndpointName = var.endpoint_name
    VariantName  = "primary"
  }

  extended_statistic  = "p99"
  period              = 300
  evaluation_periods  = 2
  threshold           = 2000000
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_description = "${var.endpoint_name} p99 latency is above 2s — check instance health"
}

# --- idle endpoint alarm ---
# fires if endpoint receives zero invocations for 24 hours
# maps directly to the Saturday LinkedIn post — catch idle endpoints before they run for months

resource "aws_cloudwatch_metric_alarm" "endpoint_idle" {
  alarm_name  = "${local.alarm_prefix}-idle"
  namespace   = "AWS/SageMaker"
  metric_name = "Invocations"

  dimensions = {
    EndpointName = var.endpoint_name
    VariantName  = "primary"
  }

  statistic           = "Sum"
  period              = 3600
  evaluation_periods  = 24
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  alarm_description = "${var.endpoint_name} has received zero invocations for 24 hours — consider scaling to zero or destroying"
}

# --- pipeline execution failure alarm ---

resource "aws_cloudwatch_metric_alarm" "pipeline_failed" {
  alarm_name  = "${local.alarm_prefix}-pipeline-failed"
  namespace   = "AWS/SageMaker"
  metric_name = "ExecutionsFailed"

  dimensions = {
    PipelineName = var.pipeline_name
  }

  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_description = "${var.pipeline_name} execution failed — check FailStep logs in CloudWatch"
}
