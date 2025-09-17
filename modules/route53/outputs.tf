# Route53 Module Outputs

output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = local.zone_id
}

output "zone_name_servers" {
  description = "Name servers for the hosted zone"
  value       = var.create_zone ? aws_route53_zone.main[0].name_servers : null
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}

output "health_check_id" {
  description = "Route53 health check ID"
  value       = aws_route53_health_check.main.id
}

output "sns_topic_arn" {
  description = "SNS topic ARN for DNS alerts"
  value       = aws_sns_topic.dns_alerts.arn
}

output "main_record_name" {
  description = "Main A record name"
  value       = aws_route53_record.main.name
}

output "api_record_name" {
  description = "API subdomain record name"
  value       = aws_route53_record.api.name
}

output "www_record_name" {
  description = "WWW subdomain record name"
  value       = aws_route53_record.www.name
}
