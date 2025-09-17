# Route53 DNS Module

This module creates Route53 hosted zones, DNS records, health checks, and query logging for domain name resolution and monitoring.

## Overview

The Route53 module provisions:
- Hosted zone creation or existing zone usage
- A records with alias to Application Load Balancer
- Health checks for endpoint monitoring
- Query logging to CloudWatch Logs
- DNSSEC support (optional)
- Multiple record types support

## Architecture

```
Domain Registrar -> Route53 Hosted Zone -> DNS Records -> ALB
                           |                     |
                    Health Checks         Query Logging
                           |                     |
                    CloudWatch Alarms    CloudWatch Logs
```

## Resources Created

- `aws_route53_zone` - Hosted zone (if creating new)
- `aws_route53_record` - DNS A records with ALB alias
- `aws_route53_health_check` - Health checks for endpoints
- `aws_cloudwatch_metric_alarm` - Health check alarms
- `aws_cloudwatch_log_group` - Query logging destination
- `aws_route53_query_log` - Query logging configuration
- `aws_sns_topic` - Health check notifications

## Features

### DNS Management
- Hosted zone creation or existing zone usage
- Alias records for AWS resources (ALB, CloudFront)
- Support for multiple record types (A, AAAA, CNAME, MX, etc.)
- TTL optimization for performance

### Health Monitoring
- HTTP/HTTPS health checks
- Geographic health checks
- Calculated health checks
- CloudWatch integration for monitoring

### Query Logging
- DNS query logging to CloudWatch
- Query analysis and monitoring
- Security and troubleshooting insights

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| domain_name | Domain name for the hosted zone | `string` | n/a | yes |
| alb_dns_name | DNS name of the Application Load Balancer | `string` | n/a | yes |
| alb_zone_id | Route53 zone ID of the ALB | `string` | n/a | yes |
| create_zone | Whether to create a new hosted zone | `bool` | `true` | no |
| enable_health_checks | Enable Route53 health checks | `bool` | `true` | no |
| enable_query_logging | Enable DNS query logging | `bool` | `true` | no |
| health_check_regions | Regions for health checks | `list(string)` | `["us-east-1", "us-west-2", "eu-west-1"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| zone_id | ID of the Route53 hosted zone |
| zone_name_servers | Name servers for the hosted zone |
| health_check_id | ID of the health check |
| query_log_id | ID of the query log configuration |

## Usage

```hcl
module "route53" {
  source = "./modules/route53"

  project_name  = "my-project"
  environment   = "prod"
  domain_name   = "example.com"
  alb_dns_name  = module.alb.alb_dns_name
  alb_zone_id   = module.alb.alb_zone_id
  
  # Optional configurations
  create_zone           = true
  enable_health_checks  = true
  enable_query_logging  = true
  health_check_regions  = ["us-east-1", "us-west-2", "eu-west-1"]
}
```

## DNS Records

### A Records
- Main domain (example.com) -> ALB
- WWW subdomain (www.example.com) -> ALB
- Alias records for zero-latency resolution

### Health Checks
- HTTP health checks on port 80 and 443
- Multiple checker regions for reliability
- CloudWatch alarms for health status

## Health Check Configuration

### HTTP Health Checks
- **Protocol**: HTTP/HTTPS
- **Port**: 80/443
- **Path**: Configurable (default: "/")
- **Interval**: 30 seconds
- **Failure Threshold**: 3 consecutive failures

### Geographic Distribution
- Health checks from multiple AWS regions
- Improved reliability and global perspective
- Faster detection of regional issues

### Alarm Integration
- CloudWatch alarms for health check failures
- SNS notifications for incidents
- Integration with monitoring dashboards

## Query Logging

### CloudWatch Integration
- All DNS queries logged to CloudWatch Logs
- Query analysis and pattern detection
- Security monitoring for DNS attacks

### Log Format
- Query timestamp and source IP
- Query type and response code
- Response data and latency

### Retention and Analysis
- Configurable log retention period
- CloudWatch Insights for query analysis
- Export to S3 for long-term storage

## Best Practices

### Domain Configuration
- Use alias records for AWS resources (lower latency)
- Implement proper TTL values for caching
- Set up health checks for critical endpoints

### Security
- Enable DNSSEC for domain integrity
- Monitor query logs for suspicious activity
- Implement DNS filtering for security

### Performance
- Use geolocation routing for global applications
- Implement latency-based routing
- Optimize TTL values for your use case

## Advanced Features

### Routing Policies
- **Simple**: Basic DNS resolution
- **Failover**: Primary/secondary endpoint routing
- **Geolocation**: Route based on user location
- **Latency**: Route to lowest latency endpoint
- **Weighted**: Distribute traffic by percentage

### DNSSEC
- DNS Security Extensions support
- Domain integrity verification
- Protection against DNS spoofing

## Integration with Other Modules

### ALB Integration
- Automatic alias record creation
- Health check integration
- SSL certificate domain validation

### CloudWatch Integration
- Health check metrics
- Query logging to CloudWatch Logs
- Alarm notifications via SNS

## Monitoring and Troubleshooting

### CloudWatch Metrics
- Health check status
- Query count and types
- Response time metrics

### Troubleshooting Tools
- Query logging analysis
- Health check failure reasons
- DNS propagation testing

### Common Issues
- DNS propagation delays
- Health check false positives
- Query logging permission errors

## Dependencies

- ALB module (DNS name and zone ID)
- CloudWatch Logs for query logging
- SNS topics for health check notifications
- Domain registrar for name server updates

## Domain Setup Process

1. **Create/Update Hosted Zone**: Terraform creates the hosted zone
2. **Update Name Servers**: Update domain registrar with Route53 name servers
3. **Verify DNS Resolution**: Test DNS resolution after propagation
4. **Configure Health Checks**: Monitor endpoint availability

## Estimated Costs

- Hosted Zone: $0.50 per month
- DNS Queries: $0.40 per million queries
- Health Checks: $0.50 per health check per month
- Query Logging: $0.50 per GB of log data
- CloudWatch Logs: $0.50 per GB ingested
