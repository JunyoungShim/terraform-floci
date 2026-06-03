# ACM
resource "aws_acm_certificate" "example_acm" {
  provider = aws.us_east_1
  domain_name = var.domain
  validation_method = "DNS"

  depends_on = [
    aws_route53_zone.example_com
  ]
}