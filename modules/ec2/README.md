# EC2 Auto Scaling Module

This module creates an Auto Scaling Group with EC2 instances, launch templates, and CloudWatch alarms for automatic scaling based on demand.

## Overview

The EC2 module provisions:
- Launch template with latest Amazon Linux 2 AMI
- Auto Scaling Group with configurable capacity
- CloudWatch alarms for scaling triggers
- IAM roles and instance profiles
- User data script for application deployment
- Integration with Application Load Balancer

## Architecture

```
Launch Template -> Auto Scaling Group -> EC2 Instances (Multi-AZ)
      |                    |                    |
   User Data         CloudWatch Alarms    Target Group
      |                    |                    |
  Application         Scaling Actions        ALB
```

## Resources Created

- `aws_launch_template` - Launch template for EC2 instances
- `aws_autoscaling_group` - Auto Scaling Group
- `aws_autoscaling_policy` - Scale up and scale down policies
- `aws_cloudwatch_metric_alarm` - CPU and memory alarms
- `aws_iam_role` - IAM role for EC2 instances
- `aws_iam_instance_profile` - Instance profile
- `aws_autoscaling_attachment` - Target group attachment

## Features

### Auto Scaling
- Automatic scaling based on CPU utilization
- Configurable minimum, maximum, and desired capacity
- Multi-AZ deployment for high availability
- Integration with ALB for health checks

### Instance Configuration
- Latest Amazon Linux 2 AMI
- Configurable instance type
- Custom user data for application setup
- IAM roles for AWS service access

### Monitoring
- CloudWatch alarms for scaling decisions
- Instance-level monitoring
- Integration with ALB health checks

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| private_subnet_ids | IDs of private subnets | `list(string)` | n/a | yes |
| security_group_id | Security group ID for EC2 instances | `string` | n/a | yes |
| target_group_arn | ARN of the ALB target group | `string` | n/a | yes |
| instance_type | EC2 instance type | `string` | `"t3.micro"` | no |
| min_size | Minimum number of instances | `number` | `1` | no |
| max_size | Maximum number of instances | `number` | `3` | no |
| desired_capacity | Desired number of instances | `number` | `2` | no |
| key_name | EC2 Key Pair name for SSH access | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| launch_template_id | ID of the launch template |
| autoscaling_group_name | Name of the Auto Scaling Group |
| autoscaling_group_arn | ARN of the Auto Scaling Group |
| iam_role_arn | ARN of the IAM role |

## Usage

```hcl
module "ec2" {
  source = "./modules/ec2"

  project_name       = "my-project"
  environment        = "prod"
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id = module.security.ec2_security_group_id
  target_group_arn  = module.alb.target_group_arn
  
  # Optional customizations
  instance_type    = "t3.small"
  min_size        = 2
  max_size        = 6
  desired_capacity = 3
  key_name        = "my-key-pair"
}
```

## User Data Script

The module includes an inline user data script that:
- Updates system packages
- Installs Apache web server
- Deploys a sample HTML application
- Configures CloudWatch agent
- Starts web services

### Application Features
- Responsive web interface
- Instance metadata display
- Health check endpoint
- Real-time system metrics

## Auto Scaling Policies

### Scale Up Policy
- **Trigger**: CPU utilization > 70% for 2 minutes
- **Action**: Add 1 instance
- **Cooldown**: 300 seconds

### Scale Down Policy
- **Trigger**: CPU utilization < 30% for 5 minutes
- **Action**: Remove 1 instance
- **Cooldown**: 300 seconds

## IAM Permissions

The EC2 instances have the following permissions:
- CloudWatch metrics and logs
- Systems Manager for patching
- S3 access for application artifacts
- Secrets Manager for configuration

## Health Checks

### ALB Health Checks
- HTTP health checks on port 80
- Path: `/` or custom health check endpoint
- Automatic instance replacement on failure

### Auto Scaling Health Checks
- EC2 status checks
- ALB health check integration
- Automatic unhealthy instance replacement

## Best Practices

### Performance
- Use appropriate instance types for workload
- Enable detailed monitoring for better scaling decisions
- Configure warm-up periods for scaling events

### Security
- Instances deployed in private subnets
- No direct internet access
- Regular security updates via user data

### Cost Optimization
- Use burstable instances (t3/t4) for variable workloads
- Configure appropriate scaling thresholds
- Monitor unused capacity

## Monitoring and Troubleshooting

### CloudWatch Metrics
- CPU utilization
- Memory utilization (with CloudWatch agent)
- Network in/out
- Application-specific metrics

### Troubleshooting
- Check Auto Scaling activity history
- Review CloudWatch logs
- Monitor ALB target health
- Verify security group rules

## Dependencies

- VPC module (subnets and VPC ID)
- Security module (security group)
- ALB module (target group)
- EC2 Key Pair (optional, for SSH access)

## Customization Options

### Instance Configuration
- Custom AMI ID
- Instance type selection
- Additional EBS volumes
- Custom user data script

### Scaling Configuration
- Custom scaling policies
- Different metric thresholds
- Scheduled scaling actions
- Predictive scaling

## Estimated Costs

- t3.micro instances: ~$6.50/month per instance
- t3.small instances: ~$13/month per instance
- CloudWatch detailed monitoring: ~$2.10/month per instance
- Data transfer costs vary by usage
