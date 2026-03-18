


# Simple fix configuration - use this if the main configuration isn't working
# This creates a very basic policy that should work

# Uncomment this resource and comment out the main policy in main.tf if needed
/*
resource "aws_api_gateway_rest_api_policy" "simple_fix" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "execute-api:Invoke"
        Resource = "*"
        Condition = {
          IpAddress = {
            "aws:sourceIp" = [
              "10.0.0.0/8",
              "172.16.0.0/12",
              "192.168.0.0/16",
              "0.0.0.0/0"  # TEMPORARY - remove this after testing
            ]
          }
        }
      }
    ]
  })

  depends_on = [
    aws_api_gateway_rest_api.main,
    aws_vpc_endpoint.api_gateway
  ]
}
*/

# Alternative: Completely open policy for testing (VERY INSECURE - testing only!)
/*
resource "aws_api_gateway_rest_api_policy" "open_for_testing" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  policy = jsonencode({
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

  depends_on = [
    aws_api_gateway_rest_api.main,
    aws_vpc_endpoint.api_gateway
  ]
}
*/


