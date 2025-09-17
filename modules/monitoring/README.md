# Monitoring Module

This module creates comprehensive CloudWatch monitoring with dashboards, alarms, Synthetics canaries, and automated reporting for infrastructure and application monitoring.

## Overview

The Monitoring module provisions:
- CloudWatch dashboards for infrastructure metrics
- Metric alarms with SNS notifications
- Synthetics canaries for application monitoring
- Lambda function for automated reporting
- Log aggregation and analysis
- Custom metrics and KPIs

## Architecture

```
Infrastructure -> CloudWatch Metrics -> Dashboards
                        |                    |
                  Metric Alarms         Synthetics
                        |                    |
                 SNS Notifications      Lambda Reports
                        |                    |
                   Email/Slack          S3/Email
```

## Resources Created

- `aws_cloudwatch_dashboard` - Infrastructure monitoring dashboard
- `aws_cloudwatch_metric_alarm` - Alarms for critical metrics
- `aws_synthetics_canary` - Application health monitoring
- `aws_lambda_function` - Automated report generation
- `aws_sns_topic` - Notification routing
- `aws_cloudwatch_log_group` - Centralized logging
- `aws_iam_role` - IAM roles for services

## Features

### Infrastructure Monitoring
- ALB metrics (request count, latency, errors)
- EC2 metrics (CPU, memory, disk, network)
- RDS metrics (connections, CPU, storage)
- Auto Scaling metrics (capacity, scaling events)

### Application Monitoring
- Synthetics canaries for endpoint testing
- HTTP response time monitoring
- Content validation and screenshot capture
- Geographic monitoring from multiple regions

### Alerting
- Multi-tier alarm thresholds
- SNS integration for notifications
- Email, SMS, and webhook support
- Alarm escalation policies

### Reporting
- Automated daily/weekly reports
- Performance trend analysis
- Cost optimization recommendations
- Security and compliance insights

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| alb_arn_suffix | ALB ARN suffix for metrics | `string` | n/a | yes |
| autoscaling_group_name | Name of the Auto Scaling Group | `string` | n/a | yes |
| domain_name | Domain name for canary monitoring | `string` | n/a | yes |
| notification_email | Email for alarm notifications | `string` | n/a | yes |
| enable_detailed_monitoring | Enable detailed CloudWatch monitoring | `bool` | `true` | no |
| canary_schedule | Schedule for Synthetics canary | `string` | `"rate(5 minutes)"` | no |
| report_schedule | Schedule for automated reports | `string` | `"cron(0 9 * * ? *)"` | no |

## Outputs

| Name | Description |
|------|-------------|
| dashboard_url | URL of the CloudWatch dashboard |
| sns_topic_arn | ARN of the SNS notification topic |
| canary_name | Name of the Synthetics canary |
| lambda_function_name | Name of the report generation Lambda |

## Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  project_name           = "my-project"
  environment            = "prod"
  alb_arn_suffix        = module.alb.alb_arn_suffix
  autoscaling_group_name = module.ec2.autoscaling_group_name
  domain_name           = "example.com"
  notification_email    = "admin@example.com"
  
  # Optional configurations
  enable_detailed_monitoring = true
  canary_schedule           = "rate(1 minute)"
  report_schedule          = "cron(0 6 * * MON *)"
}
```

## CloudWatch Dashboard

### Widget Layout
- **ALB Metrics**: Request count, response time, HTTP codes
- **EC2 Metrics**: CPU utilization, memory usage, network I/O
- **RDS Metrics**: Database connections, CPU, free storage
- **Auto Scaling**: Group size, scaling activities

### Time Ranges
- Real-time (5-minute refresh)
- Hourly, daily, weekly views
- Custom time range selection
- Comparison with previous periods

## Metric Alarms

### Critical Alarms
- **High CPU**: >80% for 5 minutes
- **High Memory**: >85% for 5 minutes  
- **ALB 5XX Errors**: >5% error rate
- **Database CPU**: >75% for 10 minutes

### Warning Alarms
- **Medium CPU**: >60% for 10 minutes
- **ALB Latency**: >2 seconds average
- **Database Connections**: >75% of max
- **Auto Scaling Events**: Frequent scaling

### Alarm Actions
- SNS notifications to operations team
- Auto Scaling policy triggers
- Lambda function for auto-remediation
- Integration with ticketing systems

## Synthetics Canaries

### Canary Features
- **HTTP Monitoring**: Response time and status codes
- **Content Validation**: Verify page content and functionality
- **Screenshot Capture**: Visual regression testing
- **Geographic Distribution**: Multi-region monitoring

### Canary Configuration
- Configurable monitoring frequency
- Custom user journey scripts
- Performance threshold alerting
- Historical trend analysis

### Built-in Canary Script
```javascript
// Inline canary script for basic HTTP monitoring
// Tests homepage, health endpoint, and API responses
// Validates response times and content
```

## Lambda Report Generation

### Report Features
- **Infrastructure Health**: Overall system status
- **Performance Metrics**: Response time trends
- **Cost Analysis**: Resource utilization and costs
- **Security Insights**: Failed requests and anomalies

### Report Delivery
- Email reports with PDF attachments
- S3 storage for historical reports
- Slack/Teams integration available
- Customizable report templates

### Built-in Report Script
```python
# Inline Python script for report generation
# Collects CloudWatch metrics
# Generates formatted reports
# Sends via email and stores in S3
```

## Log Management

### Log Sources
- ALB access logs
- EC2 application logs
- Lambda function logs
- VPC Flow Logs

### Log Analysis
- CloudWatch Insights queries
- Error pattern detection
- Performance bottleneck identification
- Security event correlation

## Best Practices

### Monitoring Strategy
- Monitor business KPIs, not just infrastructure
- Set up graduated alarm thresholds
- Use composite alarms for complex conditions
- Regular review and tuning of thresholds

### Cost Optimization
- Use metric filters to reduce log costs
- Optimize canary frequency based on criticality
- Implement log retention policies
- Monitor CloudWatch costs regularly

### Security Monitoring
- Monitor failed authentication attempts
- Track unusual traffic patterns
- Alert on configuration changes
- Implement security-specific dashboards

## Advanced Features

### Custom Metrics
- Application-specific metrics
- Business KPI tracking
- Custom CloudWatch namespaces
- Metric math for calculated values

### Anomaly Detection
- CloudWatch Anomaly Detection integration
- Machine learning-based alerting
- Seasonal pattern recognition
- Automatic threshold adjustment

### Integration Options
- Slack/Teams notifications
- PagerDuty integration
- ServiceNow ticketing
- Grafana dashboard import

## Troubleshooting

### Common Issues
- High CloudWatch costs
- False positive alarms
- Missing metrics data
- Canary failures

### Debugging Tools
- CloudWatch Logs Insights
- X-Ray tracing integration
- Metric filter testing
- Alarm history analysis

## Dependencies

- ALB module (ARN suffix for metrics)
- EC2 module (Auto Scaling Group name)
- SNS service for notifications
- Lambda service for reporting
- CloudWatch Synthetics service

## Monitoring Costs

### CloudWatch Costs
- Metrics: First 10 metrics free, then $0.30 per metric per month
- Alarms: First 10 alarms free, then $0.10 per alarm per month
- Dashboards: First 3 dashboards free, then $3 per dashboard per month
- Logs: $0.50 per GB ingested, $0.03 per GB stored

### Synthetics Costs
- Canary runs: $0.0012 per canary run
- Screenshots: Additional storage costs
- Multi-region monitoring: Costs per region

### Lambda Costs
- Function execution: Based on requests and duration
- Typically <$1/month for reporting functions

## Estimated Monthly Costs

- Basic monitoring: ~$10-20/month
- Advanced monitoring: ~$50-100/month
- Enterprise monitoring: ~$200-500/month
- Costs scale with number of resources monitored
