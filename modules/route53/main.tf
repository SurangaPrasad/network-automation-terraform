# Route53 DNS Module

# Data source for existing hosted zone (optional)
data "aws_route53_zone" "existing" {
  count = var.create_zone ? 0 : 1
  name  = var.domain_name
}

# Create new hosted zone if needed
resource "aws_route53_zone" "main" {
  count = var.create_zone ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "${var.project_name}-${var.environment}-zone"
  }
}

# Local value for zone ID
locals {
  zone_id = var.create_zone ? aws_route53_zone.main[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

# Main A record pointing to ALB
resource "aws_route53_record" "main" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# WWW subdomain record
resource "aws_route53_record" "www" {
  zone_id = local.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# API subdomain record
resource "aws_route53_record" "api" {
  zone_id = local.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Admin subdomain record
resource "aws_route53_record" "admin" {
  zone_id = local.zone_id
  name    = "admin.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Health check for the main domain
resource "aws_route53_health_check" "main" {
  fqdn                            = var.domain_name
  port                           = 443
  type                           = "HTTPS"
  resource_path                  = "/health"
  failure_threshold              = "3"
  request_interval               = "30"
  cloudwatch_alarm_region        = data.aws_region.current.name
  cloudwatch_alarm_name          = aws_cloudwatch_metric_alarm.health_check.alarm_name
  insufficient_data_health_status = "Failure"

  tags = {
    Name = "${var.project_name}-${var.environment}-health-check"
  }
}

# Data source for current region
data "aws_region" "current" {}

# CloudWatch alarm for health check
resource "aws_cloudwatch_metric_alarm" "health_check" {
  alarm_name          = "${var.project_name}-${var.environment}-health-check-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors the health check status"
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.main.id
  }

  alarm_actions = [aws_sns_topic.dns_alerts.arn]

  tags = {
    Name = "${var.project_name}-${var.environment}-health-check-alarm"
  }
}

# SNS topic for DNS alerts
resource "aws_sns_topic" "dns_alerts" {
  name = "${var.project_name}-${var.environment}-dns-alerts"

  tags = {
    Name = "${var.project_name}-${var.environment}-dns-alerts"
  }
}

# MX record for email (optional)
resource "aws_route53_record" "mx" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 300
  
  records = [
    "10 mail.${var.domain_name}",
    "20 mail2.${var.domain_name}"
  ]
}

# TXT record for domain verification
resource "aws_route53_record" "txt" {
  zone_id = local.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 300
  
  records = [
    "v=spf1 include:_spf.google.com ~all",
    "${var.project_name}-${var.environment}-verification-token"
  ]
}

# CNAME record for status page
resource "aws_route53_record" "status" {
  zone_id = local.zone_id
  name    = "status.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.alb_dns_name]
}

# Failover configuration for disaster recovery
resource "aws_route53_record" "failover_primary" {
  zone_id = local.zone_id
  name    = "failover.${var.domain_name}"
  type    = "A"

  set_identifier = "primary"
  
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.main.id

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Geolocation routing for global users
resource "aws_route53_record" "geo_us" {
  zone_id = local.zone_id
  name    = "global.${var.domain_name}"
  type    = "A"

  set_identifier = "us-users"
  
  geolocation_routing_policy {
    country = "US"
  }

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Default geolocation record
resource "aws_route53_record" "geo_default" {
  zone_id = local.zone_id
  name    = "global.${var.domain_name}"
  type    = "A"

  set_identifier = "default"
  
  geolocation_routing_policy {
    country = "*"
  }

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Query logging configuration
resource "aws_route53_query_log" "main" {
  depends_on = [aws_cloudwatch_log_group.route53_queries]
  zone_id    = local.zone_id
  destination_arn = aws_cloudwatch_log_group.route53_queries.arn
  zone_id         = local.zone_id
}

# CloudWatch log group for Route53 query logs
resource "aws_cloudwatch_log_group" "route53_queries" {
  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-route53-queries"
  }
}
