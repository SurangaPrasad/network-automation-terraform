# Main Terraform configuration file
# Network Automation Infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configuration for state management
  # Uncomment and configure when ready to use remote state
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "network-automation/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment   = var.environment
      Project       = var.project_name
      ManagedBy     = "Terraform"
      Owner         = var.owner
      CostCenter    = var.cost_center
    }
  }
}

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names
  
  # Subnet configurations
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
}

# Application Load Balancer Module
module "alb" {
  source = "./modules/alb"
  
  project_name       = var.project_name
  environment        = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = module.security_groups.alb_security_group_id
  domain_name       = var.domain_name
  route53_zone_id   = module.route53.zone_id
}

# EC2 Instances Module
module "ec2" {
  source = "./modules/ec2"
  
  project_name         = var.project_name
  environment          = var.environment
  private_subnet_ids   = module.vpc.private_subnet_ids
  security_group_id    = module.security_groups.web_security_group_id
  target_group_arn     = module.alb.target_group_arn
  instance_type        = var.instance_type
  min_size            = var.min_instances
  max_size            = var.max_instances
  desired_capacity    = var.desired_instances
}

# RDS Database Module
module "rds" {
  source = "./modules/rds"
  
  project_name          = var.project_name
  environment           = var.environment
  database_subnet_ids   = module.vpc.database_subnet_ids
  security_group_id     = module.security_groups.rds_security_group_id
  db_subnet_group_name  = module.vpc.db_subnet_group_name
  db_instance_class     = var.db_instance_class
  db_name              = var.db_name
  db_username          = var.db_username
  multi_az             = var.environment == "prod" ? true : false
}

# Route53 DNS Module
module "route53" {
  source = "./modules/route53"
  
  project_name     = var.project_name
  environment      = var.environment
  domain_name      = var.domain_name
  alb_dns_name     = module.alb.alb_dns_name
  alb_zone_id      = module.alb.alb_zone_id
  create_zone      = var.create_hosted_zone
}

# CloudWatch Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  project_name               = var.project_name
  environment                = var.environment
  autoscaling_group_name     = module.ec2.autoscaling_group_name
  alb_arn_suffix             = module.alb.alb_arn_suffix
  target_group_arn_suffix    = module.alb.target_group_arn_suffix
  domain_name                = var.domain_name
}
