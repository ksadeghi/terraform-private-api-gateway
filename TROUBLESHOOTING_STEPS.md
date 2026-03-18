
# Troubleshooting API Gateway Authorization Error

## Current Error
```
"User: anonymous is not authorized to perform: execute-api:Invoke on resource: arn:aws:execute-api:us-east-1:********4690:dfkf3ef8vf/prod/GET/ because no resource-based policy allows the execute-api:Invoke action"
```

## Step-by-Step Troubleshooting

### Step 1: Verify Terraform Changes Were Applied
First, check if the Terraform changes have been applied to your infrastructure:

```bash
# Check if your terraform.tfvars is configured
cat terraform.tfvars

# Apply the updated configuration
terraform plan
terraform apply
```

### Step 2: Check Current API Gateway Resource Policy
```bash
# Replace dfkf3ef8vf with your actual API Gateway ID
aws apigateway get-resource-policy --rest-api-id dfkf3ef8vf --region us-east-1
```

The policy should look like this after our fix:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:us-east-1:YOUR_ACCOUNT:*",
      "Condition": {
        "StringEquals": {
          "aws:sourceVpce": "vpce-xxxxxxxxx"
        }
      }
    }
  ]
}
```

### Step 3: Alternative Resource Policy (If VPC Endpoint Condition Doesn't Work)
If the VPC endpoint condition still doesn't work, try this more permissive policy that combines multiple conditions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:us-east-1:YOUR_ACCOUNT:*",
      "Condition": {
        "StringEquals": {
          "aws:sourceVpce": "vpce-xxxxxxxxx"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:us-east-1:YOUR_ACCOUNT:*",
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
}
```

### Step 4: Verify VPC Endpoint Configuration
```bash
# Get your VPC endpoint ID from Terraform output
terraform output vpc_endpoint_id

# Check VPC endpoint status
aws ec2 describe-vpc-endpoints --vpc-endpoint-ids YOUR_VPC_ENDPOINT_ID
```

### Step 5: Check Security Group Rules
```bash
# Get security group ID
terraform output security_group_id

# Check security group rules
aws ec2 describe-security-groups --group-ids YOUR_SECURITY_GROUP_ID
```

### Step 6: Test DNS Resolution
From within your VPC:
```bash
# Test DNS resolution
nslookup dfkf3ef8vf.execute-api.us-east-1.amazonaws.com

# Test with dig for more details
dig dfkf3ef8vf.execute-api.us-east-1.amazonaws.com
```

### Step 7: Alternative Testing Methods
Try these different approaches to test the API:

1. **Using VPC Endpoint DNS directly**:
   ```bash
   # Get VPC endpoint DNS names
   terraform output vpc_endpoint_dns_names
   
   # Test using VPC endpoint DNS
   curl -H "Host: dfkf3ef8vf.execute-api.us-east-1.amazonaws.com" \
        https://YOUR_VPC_ENDPOINT_DNS/prod/
   ```

2. **Using specific headers**:
   ```bash
   curl -X GET \
        -H "Host: dfkf3ef8vf.execute-api.us-east-1.amazonaws.com" \
        -H "x-apigw-api-id: dfkf3ef8vf" \
        https://dfkf3ef8vf.execute-api.us-east-1.amazonaws.com/prod/
   ```

## Common Issues and Solutions

### Issue 1: Terraform Changes Not Applied
**Solution**: Run `terraform apply` to apply the updated configuration.

### Issue 2: Wrong VPC Endpoint ID in Policy
**Solution**: Verify the VPC endpoint ID matches in both the API Gateway policy and the actual VPC endpoint.

### Issue 3: DNS Resolution Issues
**Solution**: Ensure `private_dns_enabled = true` on the VPC endpoint and that your VPC has DNS resolution enabled.

### Issue 4: Security Group Blocking Traffic
**Solution**: Verify security group allows inbound HTTPS (port 443) from your source IP ranges.

### Issue 5: Route Table Issues
**Solution**: Ensure your route tables include routes to the VPC endpoint.

## Emergency Workaround: Temporary Open Policy
If you need immediate access for testing, you can temporarily use a more open policy:

**WARNING**: This is less secure and should only be used for testing!

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "*"
    }
  ]
}
```

Apply this temporarily, test your API, then revert to the secure policy once you confirm connectivity.

## Next Steps
1. Apply the Terraform changes if you haven't already
2. Check the current resource policy
3. Try the alternative policy if needed
4. Verify VPC endpoint and security group configuration
5. Test using different methods above

Let me know which step reveals the issue, and I can provide more specific guidance.

