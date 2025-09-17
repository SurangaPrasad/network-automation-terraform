# Monitoring Module Outputs

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "canary_name" {
  description = "Name of the CloudWatch Synthetics canary"
  value       = aws_synthetics_canary.api_health.name
}

output "composite_alarm_arn" {
  description = "ARN of the composite alarm for system health"
  value       = aws_cloudwatch_composite_alarm.system_health.arn
}

output "lambda_function_name" {
  description = "Name of the report generator Lambda function"
  value       = aws_lambda_function.report_generator.function_name
}
