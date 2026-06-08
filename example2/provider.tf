provider "aws" {
  region = var.region

  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2          = var.endpoint
    iam          = var.endpoint
    lambda       = var.endpoint
    sts          = var.endpoint
    dynamodb     = var.endpoint
    apigatewayv2 = var.endpoint
  }
}
