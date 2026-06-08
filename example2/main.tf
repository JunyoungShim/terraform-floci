# DynamoDB
resource "aws_dynamodb_table" "exam2" {
  name           = "${var.system_name}-${var.environment}-dynamodb"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"

  attribute {
    name = "UserId"
    type = "S"
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "exam2" {
  name          = "${var.system_name}-${var.environment}-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "exam2" {
  api_id                 = aws_apigatewayv2_api.exam2.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.exam2.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "exam2" {
  api_id    = aws_apigatewayv2_api.exam2.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.exam2.id}"
}

resource "aws_apigatewayv2_stage" "exam2" {
  name        = "${var.system_name}-${var.environment}-stage-exam2"
  api_id      = aws_apigatewayv2_api.exam2.id
  auto_deploy = true
}

resource "aws_lambda_permission" "exam2" {
  function_name = aws_lambda_function.exam2.function_name
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.exam2.execution_arn}/*/*"
}

# Lambda
data "archive_file" "exam2" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "exam2" {
  filename         = data.archive_file.exam2.output_path
  source_code_hash = data.archive_file.exam2.output_base64sha256

  function_name = "${var.system_name}-${var.environment}-dynamodb-crud"
  role          = aws_iam_role.lambda.arn

  handler = "app.handler"
  runtime = "python3.12"
  timeout = 30

  environment {
    variables = {
      TABLE_NAME       = aws_dynamodb_table.exam2.name
      AWS_ENDPOINT_URL = "http://localhost.floci.io:4566"
    }
  }

  depends_on = [
    data.archive_file.exam2,
    aws_iam_role.lambda
  ]
}

resource "aws_iam_role" "lambda" {
  name = "${var.system_name}-${var.environment}-exam2-role"

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
  name = "${var.system_name}-${var.environment}-exam2-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
        ]
        Resource = aws_dynamodb_table.exam2.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
    ]
  })
}
