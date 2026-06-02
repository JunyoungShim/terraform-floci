resource "aws_iam_policy" "image_bucket_policy" {
  name = "${var.system_name}-${var.environment}-image-bucket-policy"
  path = "/"
  description = "Image Bucket Policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.image_bucket.arn,
          "${aws_s3_bucket.image_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "image_bucket_role" {
  name = "${var.system_name}-${var.environment}-image-bucket-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "image_bucket_role_attach" {
  role = aws_iam_role.image_bucket_role.name
  policy_arn = aws_iam_policy.image_bucket_policy.arn
}