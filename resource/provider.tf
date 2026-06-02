provider "aws" {
  region = var.region

  #下記の設定はFlociでTerraformの構築のため必要なものです。
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true

  endpoints {
    ec2 = var.endpoint
    sts = var.endpoint
    s3 = var.endpoint
    iam = var.endpoint
    route53 = var.endpoint
  }
}

provider "aws" {
  alias = "us_east_1"
  region = "us-east-1"

  #下記の設定はFlociでTerraformの構築のため必要なものです。
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check = true
  skip_requesting_account_id = true

  endpoints {
    acm = var.endpoint
  }
}