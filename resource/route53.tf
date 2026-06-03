resource "aws_route53_zone" "example_com" {
  name = var.domain
}

# ACM リソース生成だけで自動にレコードが登録されたら下記の内容は要らない
resource "aws_route53_record" "example_com" {
  for_each = {
    for dvo in aws_acm_certificate.example_acm.domain_validation_options : dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name = each.value.name
  records = [each.value.record]
  ttl = 60
  type = each.value.type
  zone_id = aws_route53_zone.example_com.zone_id
}