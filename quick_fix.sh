


#!/bin/bash

# Quick fix script for API Gateway authorization issues
# This script will help you resolve the authorization error step by step

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

API_ID="dfkf3ef8vf"
REGION="us-east-1"

print_header "Quick Fix for API Gateway Authorization"

print_header "Step 1: Update terraform.tfvars"
print_status "You need to update terraform.tfvars with your actual VPC and subnet IDs"
echo ""
echo "Current terraform.tfvars template has been created. Please edit it:"
echo "1. Replace 'vpc-xxxxxxxxx' with your actual VPC ID"
echo "2. Replace subnet IDs with your actual private subnet IDs"
echo ""
read -p "Have you updated terraform.tfvars with your actual VPC and subnet IDs? (yes/no): " updated_vars

if [ "$updated_vars" != "yes" ]; then
    print_error "Please update terraform.tfvars first, then run this script again"
    exit 1
fi

print_header "Step 2: Apply Terraform with Open Policy"
print_status "Applying Terraform configuration with open policy for testing..."
terraform init
terraform plan
read -p "Apply these changes? (yes/no): " apply_confirm

if [ "$apply_confirm" = "yes" ]; then
    terraform apply -auto-approve
    
    print_header "Step 3: Test API Access"
    print_status "Getting API Gateway URL from Terraform output..."
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
    
    if [ -n "$API_URL" ]; then
        print_status "Testing API: $API_URL"
        echo ""
        curl -v -X GET "$API_URL" 2>&1 | head -20
        echo ""
        
        print_header "Step 4: Check if it worked"
        echo ""
        read -p "Did the API call succeed (return 200 OK)? (yes/no): " api_worked
        
        if [ "$api_worked" = "yes" ]; then
            print_status "Great! The API is working with open policy."
            print_warning "Now you should secure it by changing api_policy_type to 'ip_only' or 'combined'"
            echo ""
            echo "Edit terraform.tfvars and change:"
            echo "api_policy_type = \"ip_only\"  # More secure"
            echo ""
            echo "Then run: terraform apply"
        else
            print_error "API still not working. Let's try manual policy application..."
            
            print_header "Step 5: Manual Policy Application"
            print_status "Applying policy manually using AWS CLI..."
            
            aws apigateway put-resource-policy \
              --rest-api-id $API_ID \
              --policy '{
                "Version": "2012-10-17",
                "Statement": [
                  {
                    "Effect": "Allow",
                    "Principal": "*",
                    "Action": "execute-api:Invoke",
                    "Resource": "*"
                  }
                ]
              }' \
              --region $REGION && print_status "Manual policy applied successfully" || print_error "Manual policy application failed"
            
            print_status "Testing API again..."
            curl -v -X GET "https://$API_ID.execute-api.$REGION.amazonaws.com/prod/" 2>&1 | head -20
        fi
    else
        print_error "Could not get API Gateway URL from Terraform output"
        print_status "Trying direct URL..."
        curl -v -X GET "https://$API_ID.execute-api.$REGION.amazonaws.com/prod/" 2>&1 | head -20
    fi
else
    print_error "Terraform apply cancelled"
fi

print_header "Summary"
echo ""
print_status "If the API is working now:"
echo "1. Change api_policy_type to 'ip_only' for security"
echo "2. Run 'terraform apply' to apply secure policy"
echo "3. Test again to ensure it still works"
echo ""
print_status "If it's still not working:"
echo "1. Check that you're accessing from within the VPC"
echo "2. Verify your VPC and subnet IDs are correct"
echo "3. Check AWS CLI permissions"
echo ""
print_warning "Remember to secure your API after testing!"


