locals {
  name = "${var.prefix}-ecs-ex-${replace(basename(path.cwd), "_", "-")}"

  region = data.aws_region.current.name

  tags = {
    Name    = local.name
    Prefix  = var.prefix
    Purpose = "Demo"
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

### --------------------
### Logs
### --------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name}"
  retention_in_days = 7

  tags = local.tags
}

### --------------------
### Generate randome external ID (UUID)
### --------------------
resource "random_uuid" "ex_id" {}

### --------------------
### Create VPC fore ECS
### --------------------

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = "${var.prefix}-vpc-ecr-demo"

  azs             = ["${local.region}a"]
  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true

  tags = local.tags
}

resource "aws_security_group" "broker" {
  name   = "${var.prefix}-sg-broker"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    # Should allow connection only with broker.snyk.io, but well for now...
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group" "cra" {
  name   = "${var.prefix}-sg-cra"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 8081
    to_port   = 8081
    protocol  = "tcp"
    # Only allow access from same VPC
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}
