# ALB (Application Load Balancer) Module

This module creates an Application Load Balancer with SSL/TLS termination, WAF protection, and comprehensive access logging for a highly available web application.

## Overview

The ALB module provisions:
- Application Load Balancer with multi-AZ deployment
- SSL/TLS certificate with automatic validation
- AWS WAF for application layer protection
- S3 bucket for access logs
- Target groups for EC2 instances
- Health checks and routing rules

## Architecture

```
Internet -> Route53 -> ALB (Multi-AZ) -> Target Groups -> EC2 Instances
                      |
                   AWS WAF
                      |
                  S3 Access Logs
```

## Resources Created

- `aws_lb` - Application Load Balancer
- `aws_lb_target_group` - Target group for EC2 instances
- `aws_lb_listener` - HTTP and HTTPS listeners
- `aws_acm_certificate` - SSL/TLS certificate
- `aws_acm_certificate_validation` - Certificate validation
- `aws_wafv2_web_acl` - WAF web ACL
- `aws_wafv2_web_acl_association` - WAF association with ALB
- `aws_s3_bucket` - Access logs bucket
- `aws_s3_bucket_policy` - Bucket policy for ALB logging

## Features

### High Availability
- Deployed across multiple availability zones
- Automatic failover between healthy targets
- Health checks ensure traffic only goes to healthy instances

### Security
- SSL/TLS termination with ACM certificates
- AWS WAF protection against common web exploits
- Security headers and HTTPS redirection

### Monitoring
- Access logs stored in S3
- CloudWatch metrics integration
- Health check monitoring

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| public_subnet_ids | IDs of public subnets for ALB | `list(string)` | n/a | yes |
| security_group_id | Security group ID for ALB | `string` | n/a | yes |
| domain_name | Domain name for SSL certificate | `string` | n/a | yes |
| health_check_path | Path for health checks | `string` | `"/"` | no |
| health_check_interval | Health check interval in seconds | `number` | `30` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_arn | ARN of the Application Load Balancer |
| alb_dns_name | DNS name of the Application Load Balancer |
| alb_zone_id | Route53 zone ID of the Application Load Balancer |
| alb_arn_suffix | ARN suffix for CloudWatch metrics |
| target_group_arn | ARN of the target group |
| certificate_arn | ARN of the SSL certificate |
| waf_web_acl_arn | ARN of the WAF web ACL |

## Usage

```hcl
module "alb" {
  source = "./modules/alb"

  project_name       = "my-project"
  environment        = "prod"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security.alb_security_group_id
  domain_name       = "example.com"
  
  # Optional customizations
  health_check_path     = "/health"
  health_check_interval = 15
}
```

## SSL/TLS Configuration

### Certificate Management
- Automatic certificate provisioning via AWS Certificate Manager
- DNS validation for certificate verification
- Automatic renewal before expiration

### Security Policies
- Modern TLS versions only (TLS 1.2+)
- Strong cipher suites
- Perfect Forward Secrecy support

## WAF Protection

### Built-in Rules
- SQL injection protection
- Cross-site scripting (XSS) protection
- Rate limiting for DDoS protection
- Geographic blocking capability

### Custom Rules
- IP allowlist/blocklist
- Custom request patterns
- Application-specific protections

## Health Checks

### Configuration
- HTTP health checks on configurable path
- Customizable interval and timeout
- Healthy/unhealthy thresholds

### Monitoring
- CloudWatch alarms for target health
- Automatic traffic routing to healthy targets
- Integration with Auto Scaling for instance replacement

## Access Logging

### S3 Storage
- Dedicated S3 bucket for access logs
- Organized by date and time
- Lifecycle policies for log retention

### Log Format
- Standard ALB access log format
- Request/response details
- Client IP and user agent information

## Best Practices

### Performance
- Enable HTTP/2 for improved performance
- Configure appropriate idle timeout
- Use sticky sessions if required by application

### Security
- Always use HTTPS in production
- Configure WAF rules appropriate for your application
- Regular security assessment of WAF rules

### Cost Optimization
- Right-size ALB based on traffic patterns
- Configure S3 lifecycle policies for log retention
- Monitor data transfer costs

## Dependencies

- VPC module (subnets and VPC ID)
- Security module (security group)
- Route53 hosted zone for domain validation

## Troubleshooting

### Common Issues
- Certificate validation failures
- Health check failures
- WAF blocking legitimate traffic

### Monitoring
- CloudWatch metrics for request count and latency
- Target group health in EC2 console
- WAF logs for blocked requests

## Estimated Costs

- ALB: ~$16/month base + $0.008 per LCU-hour
- SSL Certificate: Free with ACM
- WAF: ~$1/month + $0.60 per million requests
- S3 Storage: ~$0.023 per GB per month
