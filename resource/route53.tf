resource "aws_route53_zone" "example_com" {
  name = var.domain
}