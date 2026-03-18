# Terraform configuration for private HTTPS API Gateway endpoint to Lambda function

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.lambda_function_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic execution policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

# Lambda function (example - replace with your actual function)
resource "aws_lambda_function" "main" {
  filename         = "lambda_function.zip"
  function_name    = var.lambda_function_name
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "index.handler"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.lambda_logs,
  ]

  tags = var.tags
}

# Create a zip file for the Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"
  source {
    content = <<EOF
import json

def handler(event, context):
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'Hello from private Lambda API!',
            'requestId': context.aws_request_id
        })
    }
EOF
    filename = "index.py"
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = var.log_retention_days
  
  tags = var.tags
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = var.api_name
  description = "Private API Gateway for Lambda function"

  endpoint_configuration {
    types = ["PRIVATE"]
  }

  tags = var.tags
}

# API Gateway Resource
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway Method
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# API Gateway Method for root resource
resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.main.invoke_arn
}

# API Gateway Integration for root resource
resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.main.invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.stage_name

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# Security Group for VPC Endpoint
resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "${var.api_name}-vpc-endpoint-"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.api_name}-vpc-endpoint-sg"
  })
}

# VPC Endpoint for API Gateway
resource "aws_vpc_endpoint" "api_gateway" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = [
          "execute-api:Invoke"
        ]
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*/*"
        Condition = {
          IpAddress = {
            "aws:sourceIp" = var.allowed_cidr_blocks
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.api_name}-vpc-endpoint"
  })
}

# API Gateway Resource Policy (applied after both API Gateway and VPC endpoint exist)
resource "aws_api_gateway_rest_api_policy" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  policy = var.api_policy_type == "vpc_endpoint" ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.main.id}/*"
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.api_gateway.id
          }
        }
      }
    ]
  }) : var.api_policy_type == "combined" ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.main.id}/*"
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.api_gateway.id
          }
        }
      },
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.main.id}/*"
        Condition = {
          IpAddress = {
            "aws:sourceIp" = var.allowed_cidr_blocks
          }
        }
      }
    ]
  }) : var.api_policy_type == "ip_only" ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.main.id}/*"
        Condition = {
          IpAddress = {
            "aws:sourceIp" = var.allowed_cidr_blocks
          }
        }
      }
    ]
  }) : jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.main.id}/*"
      }
    ]
  })

  depends_on = [
    aws_api_gateway_rest_api.main,
    aws_vpc_endpoint.api_gateway
  ]
}


