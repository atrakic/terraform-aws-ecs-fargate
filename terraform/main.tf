provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Terraform = element(local.here, length(local.here) - 1)
    }
  }
}

provider "template" {
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  here = split("/", abspath(path.cwd))
  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "stack" {
  source = "./ecs-fargate"
  name   = var.name
  prefix = "tf"

  app = var.app

  vpc = {
    vpc_id          = module.vpc.vpc_id
    public_subnets  = module.vpc.public_subnets
    private_subnets = module.vpc.private_subnets
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = var.name

  cidr = local.cidr
  azs  = local.azs

  public_subnets  = [for k, v in local.azs : cidrsubnet(local.cidr, 8, k)]
  private_subnets = [for k, v in local.azs : cidrsubnet(local.cidr, 8, k + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}
