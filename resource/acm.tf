# ACM
resource "aws_acm_certificate" "acm" {
  provider = aws.us_east_1
  domain_name = var.domain
  validation_method = "DNS"
}