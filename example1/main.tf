# S3 Bucket
resource "aws_s3_bucket" "lambda" {
  bucket = "${var.system_name}-${var.environment}-lambda"
}

resource "aws_s3_bucket" "sqs" {
  bucket = "${var.system_name}-${var.environment}-sqs"
}

# S3 Object
resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.lambda.bucket
  key    = "lambda/app.zip"
  source = "./lambda.zip"
  etag   = filemd5("./lambda.zip")

  depends_on = [
    aws_ssm_parameter.s3_name,
    aws_ssm_parameter.sqs_name
  ]
}

# Lambda
resource "aws_lambda_function" "sqs_to_s3" {
  function_name = "${var.system_name}-${var.environment}-sqs-to-s3"
  role          = aws_iam_role.lambda.arn

  handler = "app.lambda_handler"
  runtime = "python3.12"

  s3_bucket        = aws_s3_bucket.lambda.bucket
  s3_key           = aws_s3_object.lambda_zip.key
  source_code_hash = filebase64sha256("./lambda.zip")

  timeout = 30

  environment {
    variables = {
      AWS_ENDPOINT_URL = "http://localhost.floci.io:4566"
      PARAMETER_PREFIX = "/${var.system_name}/${var.environment}"
      MAX_MESSAGES     = "10"
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda,
    aws_s3_object.lambda_zip
  ]
}

# Lambda Role
resource "aws_iam_role" "lambda" {
  name = "${var.system_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy" "lambda" {
  name = "${var.system_name}-${var.environment}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "s3:PutObject",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# SQS
resource "aws_sqs_queue" "sqs" {
  name       = "${var.system_name}-${var.environment}-sqs"
  depends_on = [aws_s3_bucket.lambda]
}

# SSM Parameter
resource "aws_ssm_parameter" "sqs_name" {
  name  = "/${var.system_name}/${var.environment}/sqs/name"
  type  = "String"
  value = aws_sqs_queue.sqs.name
}

resource "aws_ssm_parameter" "s3_name" {
  name  = "/${var.system_name}/${var.environment}/s3/name"
  type  = "String"
  value = aws_s3_bucket.sqs.bucket
}

# Scheduler
resource "aws_scheduler_schedule" "sqs_to_s3" {
  name                = "${var.system_name}-${var.environment}-sqs-to-s3-scheduler"
  schedule_expression = "rate(5 minutes)"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.sqs_to_s3.arn
    role_arn = aws_iam_role.scheduler.arn
  }
}

# Scheduler Role
resource "aws_iam_role" "scheduler" {
  name = "${var.system_name}-${var.environment}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_role_policy" "scheduler" {
  name = "${var.system_name}-${var.environment}-scheduler-policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.sqs_to_s3.arn
      }
    ]
  })
}
