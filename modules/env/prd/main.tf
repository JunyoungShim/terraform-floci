# Terraform
terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "= 6.46.0"
    }
  }
}

# Provider
provider "aws" {
  region = "ap-northeast-1"

  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true

  endpoints {
    ec2 = "http://localhost:4567"
    sts = "http://localhost:4567"
    s3 = "http://localhost:4567"
  }
}

module "vpc" {
  source = "../../template/vpc"

  system_name = var.system_name
  environment = var.environment
  vpc_cidr = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  protect_subnet_cidrs = var.protect_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}