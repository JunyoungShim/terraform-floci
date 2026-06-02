resource "aws_s3_bucket" "image_bucket" {
  bucket = "${var.system_name}-${var.environment}-image-bucket"
}