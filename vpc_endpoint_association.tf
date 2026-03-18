

# This file handles the VPC endpoint association with API Gateway
# to avoid circular dependency issues

# Data source to get the API Gateway after it's created
data "aws_api_gateway_rest_api" "main" {
  name = var.api_name
  
  depends_on = [aws_api_gateway_rest_api.main]
}

# Use AWS CLI to associate VPC endpoint with API Gateway
resource "null_resource" "associate_vpc_endpoint" {
  count = var.api_policy_type != "ip_only" ? 1 : 0
  
  triggers = {
    api_gateway_id  = aws_api_gateway_rest_api.main.id
    vpc_endpoint_id = aws_vpc_endpoint.api_gateway.id
    policy_type     = var.api_policy_type
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Update API Gateway to include VPC endpoint
      aws apigateway update-rest-api \
        --rest-api-id ${aws_api_gateway_rest_api.main.id} \
        --patch-ops op=replace,path=/endpointConfiguration/vpcEndpointIds,value='["${aws_vpc_endpoint.api_gateway.id}"]' \
        --region ${var.aws_region} || echo "VPC endpoint association may have failed, but continuing..."
    EOT
  }

  depends_on = [
    aws_api_gateway_rest_api.main,
    aws_vpc_endpoint.api_gateway,
    aws_api_gateway_deployment.main
  ]
}


