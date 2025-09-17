# VPC Module

This module creates a complete VPC infrastructure with public, private, and database subnets across multiple availability zones.

## Overview

The VPC module provisions:
- VPC with custom CIDR block
- Internet Gateway for public subnet access
- Public subnets with auto-assign public IP
- Private subnets for application servers
- Database subnets with subnet group
- NAT Gateways for private subnet internet access
- Route tables and associations
- VPC Flow Logs for network monitoring

## Architecture

```
Internet Gateway
       |
   Public Subnets (Multi-AZ)
       |
   NAT Gateways
       |
   Private Subnets (Multi-AZ)
       |
   Database Subnets (Multi-AZ)
```

## Resources Created

- `aws_vpc` - Main VPC
- `aws_internet_gateway` - Internet gateway
- `aws_subnet` - Public, private, and database subnets
- `aws_eip` - Elastic IPs for NAT gateways
- `aws_nat_gateway` - NAT gateways for private subnet internet access
- `aws_route_table` - Route tables for different subnet types
- `aws_route_table_association` - Route table associations
- `aws_db_subnet_group` - Database subnet group
- `aws_flow_log` - VPC flow logs
- `aws_cloudwatch_log_group` - Log group for VPC flow logs

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| vpc_cidr | CIDR block for VPC | `string` | n/a | yes |
| availability_zones | List of availability zones | `list(string)` | n/a | yes |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | n/a | yes |
| private_subnet_cidrs | CIDR blocks for private subnets | `list(string)` | n/a | yes |
| database_subnet_cidrs | CIDR blocks for database subnets | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| internet_gateway_id | ID of the Internet Gateway |
| public_subnet_ids | IDs of the public subnets |
| private_subnet_ids | IDs of the private subnets |
| database_subnet_ids | IDs of the database subnets |
| public_route_table_ids | IDs of the public route tables |
| private_route_table_ids | IDs of the private route tables |
| database_route_table_ids | IDs of the database route tables |
| nat_gateway_ids | IDs of the NAT gateways |
| db_subnet_group_name | Name of the database subnet group |

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  project_name     = "my-project"
  environment      = "prod"
  vpc_cidr         = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
}
```

## Features

- **Multi-AZ Architecture**: Deploys across multiple availability zones for high availability
- **Network Segmentation**: Separate subnets for public, private, and database tiers
- **Internet Access**: NAT gateways provide internet access for private subnets
- **Flow Logs**: VPC flow logs for network monitoring and security analysis
- **Flexible CIDR**: Configurable CIDR blocks for different subnet types

## Best Practices

- Use `/24` subnets to provide adequate IP addresses for scaling
- Deploy across at least 2 availability zones for redundancy
- Private subnets should host application servers without direct internet access
- Database subnets are isolated and only accessible from application tier
- VPC Flow Logs help with security monitoring and troubleshooting

## Dependencies

- AWS Provider configured with appropriate permissions
- Available availability zones in the target region

## Estimated Costs

- VPC: Free
- Internet Gateway: Free
- NAT Gateways: ~$45/month per gateway
- VPC Flow Logs: Based on data processed (~$0.50 per GB)
