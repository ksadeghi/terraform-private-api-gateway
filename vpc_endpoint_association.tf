

# This file provides additional configuration for VPC endpoint integration
# without using local-exec provisioners

# Note: The API Gateway will work with the VPC endpoint through the resource policy
# even without explicitly associating the VPC endpoint ID in the endpoint configuration.
# The key is having the correct resource policy that allows access from the VPC endpoint.

# Output information about VPC endpoint for manual configuration if needed
output "vpc_endpoint_association_info" {
  description = "Information for manual VPC endpoint association if needed"
  value = {
    message = "API Gateway should work through VPC endpoint via resource policy. If manual association is needed, use AWS CLI or console."
    api_gateway_id = aws_api_gateway_rest_api.main.id
    vpc_endpoint_id = aws_vpc_endpoint.api_gateway.id
    manual_command = "aws apigateway update-rest-api --rest-api-id ${aws_api_gateway_rest_api.main.id} --patch-ops op=replace,path=/endpointConfiguration/vpcEndpointIds,value='[\"${aws_vpc_endpoint.api_gateway.id}\"]' --region ${var.aws_region}"
  }
}


