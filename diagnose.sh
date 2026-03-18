

#!/bin/bash

# Diagnostic script for API Gateway authorization issues
# Run this to gather information about your current setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

API_ID="dfkf3ef8vf"  # Your API Gateway ID from the error message
REGION="us-east-1"

print_header "API Gateway Authorization Diagnostic"

print_header "1. Terraform Configuration Check"
if [ -f "terraform.tfvars" ]; then
    print_status "terraform.tfvars found"
    echo "Current api_policy_type:"
    grep "api_policy_type" terraform.tfvars || echo "api_policy_type not set"
    echo "Current allowed_cidr_blocks:"
    grep -A 5 "allowed_cidr_blocks" terraform.tfvars || echo "Using defaults"
else
    print_error "terraform.tfvars not found!"
fi

print_header "2. Current API Gateway Configuration"
print_status "Checking API Gateway: $API_ID"
aws apigateway get-rest-api --rest-api-id $API_ID --region $REGION 2>/dev/null || print_error "Could not get API Gateway info"

print_header "3. Current Resource Policy"
print_status "Checking resource policy..."
POLICY=$(aws apigateway get-resource-policy --rest-api-id $API_ID --region $REGION 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "$POLICY" | jq . 2>/dev/null || echo "$POLICY"
else
    print_error "No resource policy found or access denied"
fi

print_header "4. VPC Endpoint Information"
VPC_ENDPOINT_ID=$(terraform output -raw vpc_endpoint_id 2>/dev/null)
if [ -n "$VPC_ENDPOINT_ID" ]; then
    print_status "VPC Endpoint ID: $VPC_ENDPOINT_ID"
    aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $VPC_ENDPOINT_ID --region $REGION 2>/dev/null || print_error "Could not get VPC endpoint info"
else
    print_error "VPC Endpoint ID not found in Terraform output"
fi

print_header "5. Network Information"
print_status "Checking your current IP address..."
CURRENT_IP=$(curl -s https://checkip.amazonaws.com/ 2>/dev/null || curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo "unknown")
print_status "Your current IP: $CURRENT_IP"

print_status "Checking private IP (if on EC2)..."
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo "not available")
print_status "Your private IP: $PRIVATE_IP"

print_header "6. DNS Resolution Test"
print_status "Testing DNS resolution for API Gateway..."
nslookup $API_ID.execute-api.$REGION.amazonaws.com || print_error "DNS resolution failed"

print_header "7. Connectivity Test"
print_status "Testing basic connectivity to API Gateway..."
curl -v -X GET "https://$API_ID.execute-api.$REGION.amazonaws.com/prod/" 2>&1 | head -20

print_header "8. Recommendations"
echo ""
print_status "Based on the diagnostic above:"
echo "1. If no resource policy is found, that's likely the issue"
echo "2. If your IP is not in the allowed CIDR blocks, that could be the problem"
echo "3. If DNS resolution fails, there might be a VPC endpoint issue"
echo "4. Try setting api_policy_type = \"open\" temporarily for testing"
echo ""
print_warning "Quick fix commands:"
echo "# Set open policy for testing (INSECURE - testing only):"
echo "echo 'api_policy_type = \"open\"' >> terraform.tfvars"
echo "terraform apply"
echo ""
echo "# Or manually set a permissive policy:"
echo "aws apigateway put-resource-policy --rest-api-id $API_ID --policy '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"execute-api:Invoke\",\"Resource\":\"*\"}]}' --region $REGION"

