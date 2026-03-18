
# Private HTTPS API Gateway with Lambda Function

This Terraform configuration creates a private HTTPS endpoint via AWS API Gateway that connects to a Lambda function. The API is only accessible from within your VPC through a VPC endpoint, providing enhanced security for internal applications.

## Architecture Overview

```
VPC
├── Private Subnets
│   └── VPC Endpoint (Interface)
│       └── Security Group (HTTPS/443)
├── API Gateway (Private)
│   ├── REST API
│   ├── Resource & Methods
│   └── Lambda Integration
└── Lambda Function
    ├── IAM Role
    └── CloudWatch Logs
```

## Features

- **Private API Gateway**: Only accessible from within your VPC
- **HTTPS Endpoint**: Secure communication using TLS
- **VPC Endpoint**: Interface endpoint for API Gateway service
- **Lambda Integration**: Serverless function execution
- **Security Groups**: Controlled access with CIDR block restrictions
- **CloudWatch Logging**: Comprehensive logging for monitoring
- **IAM Roles**: Least privilege access for Lambda execution

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Existing VPC with private subnets
- Basic understanding of AWS networking concepts

## Required AWS Permissions

Your AWS credentials need the following permissions:
- `apigateway:*`
- `lambda:*`
- `iam:*`
- `ec2:*` (for VPC endpoints and security groups)
- `logs:*` (for CloudWatch logs)

## Quick Start

1. **Clone and Configure**
   ```bash
   # Copy the example variables file
   cp terraform.tfvars.example terraform.tfvars
   
   # Edit terraform.tfvars with your actual values
   vim terraform.tfvars
   ```

2. **Required Variables**
   Update `terraform.tfvars` with your VPC information:
   ```hcl
   vpc_id = "vpc-xxxxxxxxx"           # Your VPC ID
   subnet_ids = [                     # Your private subnet IDs
     "subnet-xxxxxxxxx",
     "subnet-yyyyyyyyy"
   ]
   ```

3. **Deploy Infrastructure**
   ```bash
   # Initialize Terraform
   terraform init
   
   # Review the plan
   terraform plan
   
   # Apply the configuration
   terraform apply
   ```

4. **Test the API**
   ```bash
   # From within your VPC (e.g., EC2 instance)
   curl -X GET "https://YOUR_API_ID.execute-api.REGION.amazonaws.com/prod/"
   ```

## Configuration Options

### Core Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `vpc_id` | VPC ID for the private endpoint | - | Yes |
| `subnet_ids` | List of private subnet IDs | - | Yes |
| `aws_region` | AWS region | `us-east-1` | No |
| `api_name` | API Gateway name | `private-lambda-api` | No |
| `lambda_function_name` | Lambda function name | `my-private-lambda` | No |

### Security Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `allowed_cidr_blocks` | CIDR blocks allowed to access the API | Private IP ranges |
| `stage_name` | API Gateway deployment stage | `prod` |

### Lambda Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `lambda_runtime` | Lambda runtime | `python3.9` |
| `lambda_timeout` | Function timeout (seconds) | `30` |
| `lambda_memory_size` | Memory allocation (MB) | `128` |

## Security Considerations

### Network Security
- API is only accessible from within the specified VPC
- Security group restricts access to HTTPS (port 443) only
- CIDR block restrictions limit source IP ranges
- VPC endpoint provides private connectivity to API Gateway service

### Access Control
- IAM roles follow least privilege principle
- Lambda execution role has minimal required permissions
- API Gateway resource policy restricts access to VPC endpoint

### Monitoring
- CloudWatch logs capture Lambda execution details
- API Gateway access logs can be enabled (optional)
- VPC Flow Logs recommended for network monitoring

## Customization

### Using Your Own Lambda Function

Replace the example Lambda function with your own:

1. **Option 1: Update the inline code**
   ```hcl
   # In main.tf, modify the archive_file data source
   data "archive_file" "lambda_zip" {
     type        = "zip"
     output_path = "lambda_function.zip"
     source {
       content  = file("${path.module}/your-function.py")
       filename = "index.py"
     }
   }
   ```

2. **Option 2: Use existing deployment package**
   ```hcl
   resource "aws_lambda_function" "main" {
     filename         = "path/to/your/function.zip"
     # ... other configuration
   }
   ```

### Adding API Gateway Methods

Add custom routes and methods:

```hcl
# Custom resource
resource "aws_api_gateway_resource" "custom" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "custom"
}

# Custom method
resource "aws_api_gateway_method" "custom" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.custom.id
  http_method   = "POST"
  authorization = "NONE"
}
```

## Troubleshooting

### Common Issues

1. **Authorization Error: "User: anonymous is not authorized to perform: execute-api:Invoke"**
   - **Root Cause**: API Gateway resource policy using IP-based restrictions doesn't work properly with VPC endpoints
   - **Solution**: The configuration now uses `aws:sourceVpce` condition instead of `aws:sourceIp`
   - **Verification**: Ensure you're accessing the API from within the VPC where the endpoint is deployed

2. **API not accessible**
   - Verify you're calling from within the VPC
   - Check security group rules allow HTTPS (port 443)
   - Confirm your source IP is within the allowed CIDR blocks
   - Ensure you're using the correct API Gateway URL format

3. **Lambda function errors**
   - Check CloudWatch logs: `/aws/lambda/YOUR_FUNCTION_NAME`
   - Verify IAM permissions for Lambda execution role
   - Test function independently using AWS CLI
   - Check Lambda function timeout and memory settings

4. **VPC endpoint issues**
   - Ensure subnets are in different AZs for high availability
   - Verify route tables have VPC endpoint routes
   - Check DNS resolution within VPC (private DNS should be enabled)
   - Confirm security group allows inbound HTTPS traffic

### Debugging Commands

```bash
# Check API Gateway deployment and resource policy
aws apigateway get-rest-api --rest-api-id YOUR_API_ID
aws apigateway get-resource-policy --rest-api-id YOUR_API_ID

# Test Lambda function directly
aws lambda invoke --function-name YOUR_FUNCTION_NAME output.json

# Check VPC endpoint status and policy
aws ec2 describe-vpc-endpoints --vpc-endpoint-ids YOUR_ENDPOINT_ID

# Verify security group rules for VPC endpoint
aws ec2 describe-security-groups --group-ids YOUR_SECURITY_GROUP_ID

# Test API connectivity from within VPC
curl -v -X GET "https://YOUR_API_ID.execute-api.REGION.amazonaws.com/prod/"

# Check DNS resolution for API Gateway
nslookup YOUR_API_ID.execute-api.REGION.amazonaws.com

# View CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/"
aws logs tail /aws/lambda/YOUR_FUNCTION_NAME --follow
```

## Cost Considerations

- **API Gateway**: $3.50 per million API calls
- **Lambda**: $0.20 per 1M requests + compute time
- **VPC Endpoint**: $0.01 per hour + $0.01 per GB processed
- **CloudWatch Logs**: $0.50 per GB ingested

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources created by this configuration.

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review AWS documentation for API Gateway and Lambda
3. Consult Terraform AWS provider documentation

## License

This configuration is provided as-is for educational and development purposes.

