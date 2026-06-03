provider "aws" {
  region = var.region

  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    ec2       = var.endpoint
    iam       = var.endpoint
    lambda    = var.endpoint
    s3        = var.endpoint
    scheduler = var.endpoint
    sqs       = var.endpoint
    ssm       = var.endpoint
    sts       = var.endpoint
  }
}
