
# Alternative API Gateway Resource Policies
# Use these if the main VPC endpoint-based policy doesn't work

# Option 1: Combined VPC Endpoint and IP-based policy (Recommended)
locals {
  combined_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
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
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
        Condition = {
          IpAddress = {
            "aws:sourceIp" = var.allowed_cidr_blocks
          }
        }
      }
    ]
  })

  # Option 2: IP-based only (fallback)
  ip_only_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
        Condition = {
          IpAddress = {
            "aws:sourceIp" = var.allowed_cidr_blocks
          }
        }
      }
    ]
  })

  # Option 3: VPC-based policy (most permissive for VPC)
  vpc_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
        Condition = {
          StringEquals = {
            "aws:sourceVpc" = var.vpc_id
          }
        }
      }
    ]
  })

  # Option 4: Open policy for testing (TEMPORARY USE ONLY)
  open_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "*"
      }
    ]
  })
}

# Uncomment one of these resource blocks to replace the main API Gateway policy

# Use this for combined VPC endpoint and IP-based policy
# resource "aws_api_gateway_rest_api_policy" "alternative_combined" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   policy      = local.combined_policy
# }

# Use this for IP-based only policy
# resource "aws_api_gateway_rest_api_policy" "alternative_ip_only" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   policy      = local.ip_only_policy
# }

# Use this for VPC-based policy
# resource "aws_api_gateway_rest_api_policy" "alternative_vpc" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   policy      = local.vpc_policy
# }

# Use this ONLY for temporary testing (REMOVE AFTER TESTING)
# resource "aws_api_gateway_rest_api_policy" "alternative_open" {
#   rest_api_id = aws_api_gateway_rest_api.main.id
#   policy      = local.open_policy
# }

