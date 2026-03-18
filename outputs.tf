

# Outputs for the private API Gateway Lambda setup

output "api_gateway_url" {
  description = "URL of the API Gateway (accessible only from within VPC)"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}"
}

output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.main.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.main.arn
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.main.invoke_arn
}

output "vpc_endpoint_id" {
  description = "ID of the VPC endpoint for API Gateway"
  value       = aws_vpc_endpoint.api_gateway.id
}

output "vpc_endpoint_dns_names" {
  description = "DNS names of the VPC endpoint"
  value       = aws_vpc_endpoint.api_gateway.dns_entry[*].dns_name
}

output "vpc_endpoint_network_interface_ids" {
  description = "Network interface IDs of the VPC endpoint"
  value       = aws_vpc_endpoint.api_gateway.network_interface_ids
}

output "security_group_id" {
  description = "ID of the security group for the VPC endpoint"
  value       = aws_security_group.vpc_endpoint.id
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Lambda"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "usage_instructions" {
  description = "Instructions for using the private API"
  value = <<-EOT
    
    PRIVATE API GATEWAY SETUP COMPLETE
    
    Your private HTTPS endpoint is now configured. Here's how to use it:
    
    1. API URL (VPC-only access): https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}
    
    2. Access Requirements:
       - Must be called from within the VPC (${var.vpc_id})
       - Source IP must be in allowed CIDR blocks: ${join(", ", var.allowed_cidr_blocks)}
    
    3. Example curl command (from within VPC):
       curl -X GET "https://${aws_api_gateway_rest_api.main.id}.execute-api.${var.aws_region}.amazonaws.com/${var.stage_name}/"
    
    4. VPC Endpoint DNS Names:
       ${join("\n       ", aws_vpc_endpoint.api_gateway.dns_entry[*].dns_name)}
    
    5. Security Group: ${aws_security_group.vpc_endpoint.id}
       - Allows HTTPS (443) from specified CIDR blocks
    
    Note: This API is only accessible from within your VPC through the VPC endpoint.
    External internet access is blocked by design for security.
    
  EOT
}

