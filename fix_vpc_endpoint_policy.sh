




#!/bin/bash

# Script to fix VPC endpoint policy blocking API Gateway access

echo "=== Fixing VPC Endpoint Policy ==="
echo ""

# First, find the VPC endpoint ID
echo "Step 1: Finding VPC endpoint for execute-api..."
VPC_ENDPOINT_ID=$(aws ec2 describe-vpc-endpoints \
  --region us-east-1 \
  --filters "Name=service-name,Values=com.amazonaws.us-east-1.execute-api" \
  --query 'VpcEndpoints[0].VpcEndpointId' \
  --output text 2>/dev/null)

if [ "$VPC_ENDPOINT_ID" = "None" ] || [ -z "$VPC_ENDPOINT_ID" ]; then
    echo "ERROR: Could not find VPC endpoint for execute-api"
    echo "Make sure you've run 'terraform apply' to create the VPC endpoint"
    exit 1
fi

echo "Found VPC endpoint: $VPC_ENDPOINT_ID"
echo ""

# Get current policy
echo "Step 2: Checking current VPC endpoint policy..."
aws ec2 describe-vpc-endpoints \
  --region us-east-1 \
  --vpc-endpoint-ids $VPC_ENDPOINT_ID \
  --query 'VpcEndpoints[0].PolicyDocument' \
  --output text

echo ""

# Apply new policy without IP restrictions
echo "Step 3: Applying new VPC endpoint policy (without IP restrictions)..."

NEW_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "*"
    }
  ]
}'

aws ec2 modify-vpc-endpoint \
  --region us-east-1 \
  --vpc-endpoint-id $VPC_ENDPOINT_ID \
  --policy-document "$NEW_POLICY"

if [ $? -eq 0 ]; then
    echo "✅ VPC endpoint policy updated successfully!"
    echo ""
    echo "Step 4: Testing API..."
    sleep 5  # Wait a moment for policy to take effect
    
    curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" \
      "https://64b9hw1bu3.execute-api.us-east-1.amazonaws.com/prod/" || \
      echo "Could not test API - check your network connectivity"
    
    echo ""
    echo "If you still get authorization errors, try:"
    echo "1. Wait 2-3 minutes for policy changes to propagate"
    echo "2. Make sure you're accessing from within the VPC"
    echo "3. Check that DNS is resolving to the VPC endpoint"
else
    echo "❌ Failed to update VPC endpoint policy"
    echo "Check your AWS CLI permissions"
fi

echo ""
echo "=== Next Steps ==="
echo "1. Test your API: curl https://64b9hw1bu3.execute-api.us-east-1.amazonaws.com/prod/"
echo "2. If working, run 'terraform apply' to make this change permanent"
echo "3. If still failing, check DNS resolution and security groups"




