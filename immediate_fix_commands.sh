



#!/bin/bash

# Immediate fix commands for your API Gateway authorization error
# Run these commands on your local machine where AWS CLI is configured

API_ID="dfkf3ef8vf"
REGION="us-east-1"

echo "=== Immediate Fix for API Gateway Authorization ==="
echo ""

echo "Step 1: Check current API Gateway status"
echo "Command: aws apigateway get-rest-api --rest-api-id $API_ID --region $REGION"
echo ""

echo "Step 2: Check if there's a current resource policy"
echo "Command: aws apigateway get-resource-policy --rest-api-id $API_ID --region $REGION"
echo ""

echo "Step 3: Apply open resource policy (TEMPORARY - for testing)"
echo "Command:"
cat << 'EOF'
aws apigateway put-resource-policy \
  --rest-api-id dfkf3ef8vf \
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
  --region us-east-1
EOF

echo ""
echo "Step 4: Test the API"
echo "Command: curl -X GET \"https://$API_ID.execute-api.$REGION.amazonaws.com/prod/\""
echo ""

echo "Step 5: After testing works, apply secure policy"
echo "Command:"
cat << 'EOF'
aws apigateway put-resource-policy \
  --rest-api-id dfkf3ef8vf \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": "*",
        "Condition": {
          "IpAddress": {
            "aws:sourceIp": [
              "10.0.0.0/8",
              "172.16.0.0/12", 
              "192.168.0.0/16"
            ]
          }
        }
      }
    ]
  }' \
  --region us-east-1
EOF

echo ""
echo "=== Copy and paste these commands in your local terminal ==="
echo ""
echo "IMPORTANT: Make sure you're running these from within your VPC"
echo "           (e.g., from an EC2 instance or through VPN/Direct Connect)"



