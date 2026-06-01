# S3
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.system_name}-${var.environment}-frontend"
}