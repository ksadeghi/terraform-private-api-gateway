




#!/bin/bash

# Debug script for API Gateway authorization issues
# Run this to gather diagnostic information

API_ID="dfkf3ef8vf"
REGION="us-east-1"

echo "=== API Gateway Authorization Debug ==="
echo "API ID: $API_ID"
echo "Region: $REGION"
echo ""

echo "=== 1. Checking AWS CLI Configuration ==="
aws sts get-caller-identity 2>/dev/null || echo "ERROR: AWS CLI not configured or no permissions"
echo ""

echo "=== 2. Checking API Gateway Exists ==="
aws apigateway get-rest-api --rest-api-id $API_ID --region $REGION 2>/dev/null || echo "ERROR: Cannot access API Gateway $API_ID"
echo ""

echo "=== 3. Checking Current Resource Policy ==="
POLICY=$(aws apigateway get-resource-policy --rest-api-id $API_ID --region $REGION 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$POLICY" ]; then
    echo "Resource policy found:"
    echo "$POLICY" | jq . 2>/dev/null || echo "$POLICY"
else
    echo "NO RESOURCE POLICY FOUND - This is likely the problem!"
fi
echo ""

echo "=== 4. Checking API Gateway Configuration ==="
aws apigateway get-rest-api --rest-api-id $API_ID --region $REGION --query '{name:name,endpointConfiguration:endpointConfiguration,policy:policy}' 2>/dev/null || echo "ERROR: Cannot get API configuration"
echo ""

echo "=== 5. Testing API Connectivity ==="
echo "Testing: https://$API_ID.execute-api.$REGION.amazonaws.com/prod/"
curl -s -o /dev/null -w "HTTP Status: %{http_code}\nTime: %{time_total}s\n" "https://$API_ID.execute-api.$REGION.amazonaws.com/prod/" 2>/dev/null || echo "ERROR: Cannot connect to API"
echo ""

echo "=== 6. Recommended Fix Commands ==="
echo ""
echo "If NO RESOURCE POLICY found above, run this:"
echo "aws apigateway put-resource-policy --rest-api-id $API_ID --policy '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"execute-api:Invoke\",\"Resource\":\"*\"}]}' --region $REGION"
echo ""
echo "Then redeploy the API:"
echo "aws apigateway create-deployment --rest-api-id $API_ID --stage-name prod --region $REGION"
echo ""
echo "If policy exists but still getting errors, try removing it:"
echo "aws apigateway delete-resource-policy --rest-api-id $API_ID --region $REGION"




