# Retrieve the list of AZs in the current AWS region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  common_tags = {
    Environment = "development"
    Project     = "3-tier architecture"
  }
}

module "vpc" {
  source = "./modules/vpc"

  cidr_block = var.vpc_cidr_block

  tags = local.common_tags
  tags_for_resource = {
    aws_vpc = {
      Name = var.vpc_name
    }

    aws_internet_gateway = {
      Name = "MyIGW - ${var.vpc_name}"
    }
  }
}

module "web_tier" {
  source = "./modules/public-subnets"

  vpc_id                  = module.vpc.vpc_id
  gateway_id              = module.vpc.internet_gateway_id
  map_public_ip_on_launch = true

  cidr_block         = var.public_cidr_block
  subnet_count       = var.public_subnet_count
  availability_zones = data.aws_availability_zones.available.names

  tags = local.common_tags
  tags_for_resource = {
    aws_subnet = {
      Name = "Web Tier Public Subnet - ${var.vpc_name}"
    }

    aws_route_table = {
      Name = "Public Subnet Route Table - ${var.vpc_name}"
    }
  }
}

module "nat_gateways" {
  source = "./modules/nat-gateways"

  subnet_count = module.web_tier.subnet_count
  subnet_ids   = module.web_tier.subnet_ids

  tags = local.common_tags
  tags_for_resource = {
    aws_eip = {
      Name = "EIP - ${var.vpc_name}"
    }

    aws_nat_gateway = {
      Name = "NAT_GW - ${var.vpc_name}"
    }
  }
}

module "application_tier" {
  source = "./modules/private-subnets"

  vpc_id             = module.vpc.vpc_id
  cidr_block         = var.application_tier_cidr_block
  subnet_count       = var.private_subnet_count
  availability_zones = data.aws_availability_zones.available.names

  tags = local.common_tags
  tags_for_resource = {
    aws_subnet = {
      Name = "Application Tier - Private Subnet - ${var.vpc_name}"
    }

    aws_route_table = {
      Name = "Application Tier - Private Subnet Route Table - ${var.vpc_name}"
    }
  }
}

module "database_tier" {
  source = "./modules/private-subnets"

  vpc_id             = module.vpc.vpc_id
  cidr_block         = var.database_tier_cidr_block
  subnet_count       = var.private_subnet_count
  availability_zones = data.aws_availability_zones.available.names

  tags = local.common_tags
  tags_for_resource = {
    aws_subnet = {
      Name = "Database Tier - Private Subnet - ${var.vpc_name}"
    }

    aws_route_table = {
      Name = "Database Tier - Private Subnet Route Table - ${var.vpc_name}"
    }
  }
}

# Lookup Amazon Linux 2023
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.5.20240722.0-kernel-6.1-x86_64"]
  }

  owners = ["amazon"]
}

/*************************************
          Web Tier Resources
*************************************/

# Security group to allow access on port 80 from anywhere
module "security_group_web_alb" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = var.sg_name
  description = var.sg_description
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule = "all-all"
    }
  ]


  tags = merge(local.common_tags, {
    Name = "Web Tier ALB - Security Group"
  })
}

# Security group to allow access on port 80 from the source load balancer
module "security_group_web_instance" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = var.instance_sg_name
  description = var.instance_sg_description
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "HTTP access through LB"
      rule                     = "http-80-tcp"
      source_security_group_id = module.security_group_web_alb.security_group_id
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule = "all-all"
    }
  ]


  tags = merge(local.common_tags, {
    Name = "Web Tier Instance - Security Group"
  })
}

# Auto Scaling Group module for instances
module "web_tier_asg" {
  source = "./modules/auto-scaling-group"

  # ASG
  asg_name   = "web-tier-asg"
  subnet_ids = module.web_tier.subnet_ids

  # Launch Template
  launch_template_name = "web-tier-launch-template"
  ami_id               = data.aws_ami.amazon_linux.id
  security_groups      = [module.security_group_web_instance.security_group_id]
}

# Load Balancer module to direct request to instances
module "web_tier_alb" {
  source = "./modules/load-balancer"

  # Load Balancer
  load_balancer_name     = "web-tier-alb"
  subnet_ids             = module.web_tier.subnet_ids
  alb_security_group_ids = [module.security_group_web_alb.security_group_id]

  # Target Group
  target_group_name = "web-tier-alb-tg"
  vpc_id            = module.vpc.vpc_id

}

# Resource block to attach a load balancer to an auto scaling group
resource "aws_autoscaling_attachment" "web-tier-asg-attachment" {
  autoscaling_group_name = module.web_tier_asg.asg_id
  lb_target_group_arn    = module.web_tier_alb.alb_tg_arn
}

output "web-tier-alb-dns-name" {
  description = "DNS name for the Web Tier load balancer"
  value       = module.web_tier_alb.alb_dns_name
}


/*************************************
          App Tier Resources
*************************************/

# Security group 
# Allow inbound access on port 80 from web tier security group
# Allow outbound to anywhere
module "security_group_app_alb" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = var.app_alb_sg_name
  description = var.app_alb_sg_description
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "HTTP access through LB"
      rule                     = "http-80-tcp"
      source_security_group_id = module.security_group_web_instance.security_group_id
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule = "all-all"
    }
  ]


  tags = merge(local.common_tags, {
    Name = "App Tier ALB - Security Group"
  })
}

# Security group
# Allow inbound access to app tier load balancer on port 4000
# Allow all outbound access
module "security_group_app_instance" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = var.app_instance_sg_name
  description = var.app_instance_sg_description
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      description              = "HTTP access through LB"
      from_port                = 4000
      to_port                  = 4000
      protocol                 = "tcp"
      source_security_group_id = module.security_group_app_alb.security_group_id
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule = "all-all"
    }
  ]


  tags = merge(local.common_tags, {
    Name = "App Tier Instance - Security Group"
  })
}

# Auto Scaling Group module for instances
module "app_tier_asg" {
  source = "./modules/auto-scaling-group"

  # ASG
  asg_name   = "app-tier-asg"
  subnet_ids = module.application_tier.subnet_ids

  # Launch Template
  launch_template_name = "app-tier-launch-template"
  ami_id               = data.aws_ami.amazon_linux.id
  security_groups      = [module.security_group_app_instance.security_group_id]
}

# Load Balancer module to direct request to instances
module "app_tier_alb" {
  source = "./modules/load-balancer"

  # Load Balancer
  load_balancer_name     = "app-tier-alb"
  subnet_ids             = module.application_tier.subnet_ids
  alb_security_group_ids = [module.security_group_app_alb.security_group_id]

  # Target Group
  target_group_name = "app-tier-alb-tg"
  vpc_id            = module.vpc.vpc_id
}

# Resource block to attach a load balancer to an auto scaling group
resource "aws_autoscaling_attachment" "app-tier-asg-attachment" {
  autoscaling_group_name = module.app_tier_asg.asg_id
  lb_target_group_arn    = module.app_tier_alb.alb_tg_arn
}

output "app-tier-alb-dns-name" {
  description = "DNS name for the Application Tier load balancer"
  value       = module.app_tier_alb.alb_dns_name
}

/*************************************
        Database Tier Resources
*************************************/
resource "aws_db_subnet_group" "private_subnets" {
  name       = "Private Subnets"
  subnet_ids = module.database_tier.subnet_ids
}

# Security Group for DB Access
module "app_db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = var.app_db_sg_name
  description = var.app_db_sg_description
  vpc_id      = module.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.security_group_app_instance.security_group_id
    },
  ]

  egress_with_cidr_blocks = [
    {
      rule = "all-all"
    }
  ]


  tags = merge(local.common_tags, {
    Name = "Database Tier - Security Group"
  })
}

# Retrieve database credentials from Secrets Manager
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = "aurora-db-credentials"
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}


# Aurora DB Cluster
resource "aws_rds_cluster" "aurora_db" {
  cluster_identifier      = "aurora-cluster"
  engine                  = "aurora-mysql"
  engine_version          = "5.7.12"
  availability_zones      = data.aws_availability_zones.available.names
  database_name           = "mydb"
  master_username         = local.db_credentials.username
  master_password         = local.db_credentials.password
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"

  vpc_security_group_ids = [app_db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.private_subnets.name
}