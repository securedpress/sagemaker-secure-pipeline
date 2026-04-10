output "idle_alarm_name" {
  value = aws_cloudwatch_metric_alarm.endpoint_idle.alarm_name
}

output "pipeline_failed_alarm_name" {
  value = aws_cloudwatch_metric_alarm.pipeline_failed.alarm_name
}
