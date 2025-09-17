# RDS Database Module

This module creates a highly available, encrypted RDS MySQL database with Multi-AZ deployment, automated backups, and secure credential management.

## Overview

The RDS module provisions:
- RDS MySQL instance with Multi-AZ deployment
- Database subnet group for network isolation
- Parameter and option groups for optimization
- KMS encryption for data at rest
- AWS Secrets Manager for credential storage
- CloudWatch monitoring and alarms
- Automated backup and maintenance windows

## Architecture

```
Application Tier -> RDS Proxy (Optional) -> RDS MySQL (Multi-AZ)
                                               |
                                        Read Replicas
                                               |
                                        Automated Backups
                                               |
                                         KMS Encryption
```

## Resources Created

- `aws_db_instance` - RDS MySQL database
- `aws_db_subnet_group` - Database subnet group
- `aws_db_parameter_group` - Custom parameter group
- `aws_db_option_group` - Database option group
- `aws_kms_key` - KMS key for encryption
- `aws_secretsmanager_secret` - Database credentials
- `aws_cloudwatch_metric_alarm` - Database monitoring alarms
- `aws_sns_topic` - Notifications for alerts

## Features

### High Availability
- Multi-AZ deployment for automatic failover
- Automated backup with point-in-time recovery
- Read replicas for read scaling (optional)
- Cross-region backup replication (optional)

### Security
- KMS encryption for data at rest
- Encryption in transit with SSL/TLS
- VPC isolation in database subnets
- IAM database authentication support
- Secrets Manager for credential rotation

### Performance
- Optimized parameter groups
- Performance Insights enabled
- CloudWatch monitoring
- Configurable instance classes

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| database_subnet_ids | IDs of database subnets | `list(string)` | n/a | yes |
| security_group_id | Security group ID for RDS | `string` | n/a | yes |
| db_name | Name of the database | `string` | n/a | yes |
| db_username | Master username for database | `string` | `"admin"` | no |
| db_instance_class | RDS instance class | `string` | `"db.t3.micro"` | no |
| allocated_storage | Allocated storage in GB | `number` | `20` | no |
| max_allocated_storage | Maximum allocated storage in GB | `number` | `100` | no |
| backup_retention_period | Backup retention period in days | `number` | `7` | no |
| multi_az | Enable Multi-AZ deployment | `bool` | `true` | no |
| deletion_protection | Enable deletion protection | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | ID of the RDS instance |
| db_instance_endpoint | RDS instance endpoint |
| db_instance_port | RDS instance port |
| db_instance_arn | ARN of the RDS instance |
| db_subnet_group_name | Name of the database subnet group |
| db_parameter_group_name | Name of the parameter group |
| kms_key_id | ID of the KMS key |
| secret_arn | ARN of the Secrets Manager secret |

## Usage

```hcl
module "rds" {
  source = "./modules/rds"

  project_name        = "my-project"
  environment         = "prod"
  vpc_id             = module.vpc.vpc_id
  database_subnet_ids = module.vpc.database_subnet_ids
  security_group_id  = module.security.rds_security_group_id
  
  db_name            = "myapp"
  db_username        = "admin"
  db_instance_class  = "db.t3.small"
  allocated_storage  = 100
  
  # Production settings
  multi_az              = true
  deletion_protection   = true
  backup_retention_period = 30
}
```

## Database Configuration

### MySQL Version
- MySQL 8.0 (latest stable version)
- Regular minor version updates during maintenance windows
- Parameter group optimized for performance

### Storage
- General Purpose SSD (gp2) storage
- Storage auto-scaling enabled
- Encrypted at rest with KMS

### Backup Configuration
- Automated daily backups
- Configurable retention period (1-35 days)
- Point-in-time recovery capability
- Manual snapshots for special events

## Security Features

### Encryption
- **At Rest**: KMS encryption for database storage
- **In Transit**: SSL/TLS encryption for connections
- **Backups**: Encrypted automated and manual snapshots

### Access Control
- Database deployed in private subnets
- Security group restricts access to application tier only
- IAM database authentication available
- Secrets Manager for credential management

### Credential Management
- Random password generation
- Automatic credential rotation (configurable)
- Secure storage in AWS Secrets Manager
- Application retrieves credentials via IAM roles

## Monitoring and Alerting

### CloudWatch Metrics
- CPU utilization
- Database connections
- Read/write latency
- Free storage space
- Replica lag (if applicable)

### Alarms
- High CPU utilization (>80%)
- Low free storage space (<10%)
- High connection count (>80% of max)
- Automatic notifications via SNS

### Performance Insights
- SQL query analysis
- Wait event monitoring
- Database load tracking
- Performance tuning recommendations

## Maintenance

### Maintenance Windows
- Configurable weekly maintenance window
- Automatic minor version updates
- Minimal downtime with Multi-AZ

### Backup Strategy
- Daily automated backups
- Long-term retention for compliance
- Cross-region backup for disaster recovery
- Manual snapshots before major changes

## Best Practices

### Performance
- Choose appropriate instance class for workload
- Enable Performance Insights for monitoring
- Use read replicas for read-heavy workloads
- Monitor and optimize slow queries

### Security
- Regular security updates during maintenance windows
- Implement least privilege access
- Enable encryption for sensitive data
- Regular credential rotation

### Cost Optimization
- Use appropriate instance sizing
- Implement storage auto-scaling
- Consider Reserved Instances for production
- Monitor unused database capacity

## Dependencies

- VPC module (database subnets)
- Security module (RDS security group)
- KMS key for encryption
- IAM roles for Secrets Manager access

## Disaster Recovery

### Multi-AZ Deployment
- Synchronous replication to standby instance
- Automatic failover in case of primary failure
- Typically 60-120 seconds for failover

### Cross-Region Backups
- Automated backup replication to different region
- Manual snapshot copying for compliance
- Full restore capability in disaster scenarios

## Troubleshooting

### Common Issues
- Connection timeout from application
- Storage space running low
- Performance degradation
- Authentication failures

### Monitoring Tools
- CloudWatch metrics and logs
- Performance Insights dashboard
- RDS Events for operational notifications
- VPC Flow Logs for network troubleshooting

## Estimated Costs

- db.t3.micro: ~$13/month
- db.t3.small: ~$26/month
- db.t3.medium: ~$52/month
- Storage: ~$0.115 per GB per month
- Backup storage: Free up to 100% of allocated storage
- Multi-AZ: 2x instance cost
- Performance Insights: Free for 7 days retention
