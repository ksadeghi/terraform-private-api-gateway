

# Immediate Fix for Authorization Error

You're still getting the authorization error, which means the resource policy isn't working as expected. Let's fix this step by step.

## Step 1: Check Current Configuration

First, let's see what's currently deployed:

```bash
# Check if you have a terraform.tfvars file
cat terraform.tfvars

# Check current Terraform state
terraform show | grep -A 20 "aws_api_gateway_rest_api_policy"
```

## Step 2: Try the Open Policy (Temporary)

To confirm connectivity works, let's temporarily use an open policy:

1. **Edit terraform.tfvars**:
   ```hcl
   api_policy_type = "open"
   ```

2. **Apply the change**:
   ```bash
   terraform apply
   ```

3. **Test the API**:
   ```bash
   curl -X GET "https://dfkf3ef8vf.execute-api.us-east-1.amazonaws.com/prod/"
   ```

If this works, the issue is with the policy conditions, not the basic setup.

## Step 3: Check Your Source IP

From within your VPC, check what IP address you're coming from:

```bash
# Check your current IP
curl -s https://checkip.amazonaws.com/

# Or if you're on an EC2 instance
curl -s http://169.254.169.254/latest/meta-data/local-ipv4
```

Make sure this IP is within your `allowed_cidr_blocks` in terraform.tfvars.

## Step 4: Verify VPC Endpoint

Check if the VPC endpoint is working:

```bash
# Get VPC endpoint info
terraform output vpc_endpoint_id
terraform output vpc_endpoint_dns_names

# Test DNS resolution
nslookup dfkf3ef8vf.execute-api.us-east-1.amazonaws.com
```

## Step 5: Manual Policy Fix

If the Terraform policy isn't working, you can manually set a policy using AWS CLI:

```bash
# Get your API Gateway ID and VPC Endpoint ID
API_ID="dfkf3ef8vf"
VPC_ENDPOINT_ID=$(terraform output -raw vpc_endpoint_id)

# Apply a simple IP-based policy manually
aws apigateway put-resource-policy \
  --rest-api-id $API_ID \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": "*",
        "Action": "execute-api:Invoke",
        "Resource": "arn:aws:execute-api:us-east-1:*:*/*",
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
```

## Step 6: Check Current Policy

Verify what policy is actually applied:

```bash
aws apigateway get-resource-policy --rest-api-id dfkf3ef8vf --region us-east-1
```

## Step 7: Alternative Approach - Remove Policy Entirely

Sometimes the simplest approach works:

```bash
# Remove the resource policy entirely (makes API accessible from VPC)
aws apigateway delete-resource-policy --rest-api-id dfkf3ef8vf --region us-east-1
```

**WARNING**: This removes all access restrictions, so only do this for testing!

## Quick Diagnosis Commands

Run these to gather information:

```bash
echo "=== API Gateway Info ==="
aws apigateway get-rest-api --rest-api-id dfkf3ef8vf --region us-east-1

echo "=== Current Resource Policy ==="
aws apigateway get-resource-policy --rest-api-id dfkf3ef8vf --region us-east-1 2>/dev/null || echo "No policy found"

echo "=== VPC Endpoint Status ==="
VPC_ENDPOINT_ID=$(terraform output -raw vpc_endpoint_id 2>/dev/null)
if [ -n "$VPC_ENDPOINT_ID" ]; then
  aws ec2 describe-vpc-endpoints --vpc-endpoint-ids $VPC_ENDPOINT_ID --region us-east-1
else
  echo "VPC Endpoint ID not found in Terraform output"
fi

echo "=== Your Current IP ==="
curl -s https://checkip.amazonaws.com/ || curl -s http://169.254.169.254/latest/meta-data/local-ipv4 || echo "Could not determine IP"
```

## Most Likely Issues

1. **Policy not applied**: The `aws_api_gateway_rest_api_policy` resource might not be working
2. **Wrong IP range**: Your source IP isn't in the allowed CIDR blocks
3. **VPC endpoint not associated**: The API Gateway doesn't know about the VPC endpoint
4. **DNS resolution**: You're not hitting the VPC endpoint

Try the steps above in order, and let me know what you find!


