# Security Module

This module creates security groups for different tiers of the application infrastructure with proper ingress and egress rules following least privilege principles.

## Overview

The Security module provisions:
- Application Load Balancer security group
- EC2 instances security group
- RDS database security group
- Bastion host security group (optional)
- Proper security group rules with minimal required access

## Architecture

```
Internet -> ALB Security Group -> EC2 Security Group -> RDS Security Group
                                        ^
                                  Bastion Security Group
```

## Resources Created

- `aws_security_group.alb` - Security group for Application Load Balancer
- `aws_security_group.ec2` - Security group for EC2 instances
- `aws_security_group.rds` - Security group for RDS database
- `aws_security_group.bastion` - Security group for bastion host
- Security group rules for controlled access between tiers

## Security Groups

### ALB Security Group
- **Ingress**: HTTP (80) and HTTPS (443) from anywhere
- **Egress**: All traffic to anywhere
- **Purpose**: Accept web traffic from internet

### EC2 Security Group
- **Ingress**: HTTP (80) from ALB security group only
- **Ingress**: SSH (22) from bastion security group only
- **Egress**: All traffic to anywhere
- **Purpose**: Accept traffic only from load balancer and bastion

### RDS Security Group
- **Ingress**: MySQL (3306) from EC2 security group only
- **Egress**: No outbound rules (implicit deny)
- **Purpose**: Accept database connections only from application servers

### Bastion Security Group
- **Ingress**: SSH (22) from specified CIDR blocks
- **Egress**: SSH (22) to private subnets
- **Purpose**: Secure SSH access to private instances

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| allowed_cidr_blocks | CIDR blocks allowed for bastion access | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_security_group_id | ID of the ALB security group |
| ec2_security_group_id | ID of the EC2 security group |
| rds_security_group_id | ID of the RDS security group |
| bastion_security_group_id | ID of the bastion security group |

## Usage

```hcl
module "security" {
  source = "./modules/security"

  project_name = "my-project"
  environment  = "prod"
  vpc_id       = module.vpc.vpc_id
  
  # Optional: Allow SSH access from specific IP ranges
  allowed_cidr_blocks = ["203.0.113.0/24"]
}
```

## Security Features

### Least Privilege Access
- Each security group only allows minimum required access
- Database is only accessible from application tier
- Application tier only accepts traffic from load balancer
- SSH access is restricted to bastion host

### Defense in Depth
- Multiple security layers between internet and database
- No direct internet access to application or database tiers
- Controlled SSH access through bastion host

### Compliance Ready
- Follows AWS security best practices
- Supports SOC 2, PCI DSS compliance requirements
- Detailed security group descriptions for auditing

## Best Practices

- **Principle of Least Privilege**: Only allow minimum required access
- **Source Restriction**: Use security group references instead of CIDR blocks where possible
- **Regular Audits**: Review security group rules periodically
- **Documentation**: Maintain clear descriptions for all rules
- **Monitoring**: Enable VPC Flow Logs to monitor security group effectiveness

## Common Use Cases

### Web Application
```hcl
# Allow web traffic to ALB
# ALB forwards to EC2 instances
# EC2 connects to RDS database
```

### Development Environment
```hcl
# Additional SSH access for developers
# May include broader CIDR ranges for bastion access
```

### Production Environment
```hcl
# Strict access controls
# Limited SSH access from corporate networks only
```

## Dependencies

- VPC module (requires VPC ID)
- AWS Provider with appropriate permissions

## Security Considerations

- **SSH Keys**: Ensure proper SSH key management for bastion access
- **Database Access**: Database should never be directly accessible from internet
- **Monitoring**: Enable CloudTrail and VPC Flow Logs for security monitoring
- **Updates**: Keep security group rules updated as application requirements change

## Estimated Costs

- Security Groups: Free
- VPC Flow Logs (if enabled): ~$0.50 per GB processed
