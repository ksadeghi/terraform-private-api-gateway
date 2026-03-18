





# VPC Endpoint Policy Blocking API Gateway Access

## The Current Issue
Error: "no VPC endpoint policy allows the execute-api:Invoke action"

This means:
✅ **API Gateway resource policy is working** (we fixed that!)  
❌ **VPC endpoint policy is blocking the request**

## Immediate Fix Options

### Option A: Quick Fix with AWS CLI (Recommended)
```bash
# Pull latest changes
git pull origin terraform-private-api-gateway

# Run the fix script
./fix_vpc_endpoint_policy.sh
```

### Option B: Manual AWS CLI Commands
```bash
# 1. Find your VPC endpoint ID
aws ec2 describe-vpc-endpoints \
  --region us-east-1 \
  --filters "Name=service-name,Values=com.amazonaws.us-east-1.execute-api" \
  --query 'VpcEndpoints[0].VpcEndpointId' \
  --output text

# 2. Apply open policy (replace VPC_ENDPOINT_ID with actual ID)
aws ec2 modify-vpc-endpoint \
  --region us-east-1 \
  --vpc-endpoint-id VPC_ENDPOINT_ID \
  --policy-document '{
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

# 3. Test API
curl -X GET "https://64b9hw1bu3.execute-api.us-east-1.amazonaws.com/prod/"
```

### Option C: Terraform Apply (Slower)
```bash
# This will eventually work but takes longer
terraform apply
```

## Why This Happened

The VPC endpoint was created with a restrictive policy that included IP address conditions:

```json
{
  "Condition": {
    "IpAddress": {
      "aws:sourceIp": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
    }
  }
}
```

**Problem**: Your request's source IP didn't match these CIDR blocks, so the VPC endpoint blocked it.

**Solution**: Remove the IP condition since the VPC endpoint already restricts access to your VPC.

## Understanding the Error Progression

1. **Original Error**: "no resource-based policy allows" → **Fixed** ✅
2. **Current Error**: "no VPC endpoint policy allows" → **Fixing now** 🔧
3. **Expected Next**: API works! 🎉

## After the Fix Works

Once your API is working, you can secure it properly:

1. **Test with open policy first** (what we're doing now)
2. **Verify it works from your VPC**
3. **Apply appropriate restrictions** based on your security requirements

## Common VPC Endpoint Policy Patterns

### Most Permissive (Testing)
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

### Restrict to Specific API
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:us-east-1:*:64b9hw1bu3/*"
    }
  ]
}
```

### Restrict to Specific Subnets (Advanced)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:sourceVpce": "vpce-your-endpoint-id"
        }
      }
    }
  ]
}
```

## Troubleshooting Tips

### If the fix script fails:
1. **Check AWS CLI permissions** - You need `ec2:DescribeVpcEndpoints` and `ec2:ModifyVpcEndpoint`
2. **Verify VPC endpoint exists** - Run `terraform apply` first if needed
3. **Check region** - Make sure you're in `us-east-1`

### If API still doesn't work after policy fix:
1. **Wait 2-3 minutes** for policy changes to propagate
2. **Check DNS resolution** - Make sure you're using VPC endpoint DNS
3. **Verify security groups** - Port 443 must be allowed
4. **Test from within VPC** - Must be from EC2 instance or through VPN

## Success Indicators

✅ **VPC endpoint policy updated successfully**  
✅ **API returns 200 OK instead of 403 Forbidden**  
✅ **Can access API from within VPC**  

## Next Steps After Success

1. **Run `terraform apply`** to make the fix permanent
2. **Test thoroughly** from your applications
3. **Apply appropriate security restrictions** if needed
4. **Document the working configuration** for your team

The key insight is that VPC endpoint policies and API Gateway resource policies work together - both must allow the request for it to succeed.





