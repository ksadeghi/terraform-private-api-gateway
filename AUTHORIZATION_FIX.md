
# Fix for API Gateway Authorization Error

## Problem
You were encountering the following error when trying to access your private API Gateway from within the same VPC:

```
"User: anonymous is not authorized to perform: execute-api:Invoke on resource: arn:aws:execute-api:us-east-1:********4690:dfkf3ef8vf/prod/GET/ because no resource-based policy allows the execute-api:Invoke action"
```

## Root Cause
The issue was in the API Gateway resource policy configuration. The original policy used an IP-based restriction (`aws:sourceIp`) which doesn't work properly when accessing private API Gateway endpoints through VPC endpoints. When requests come through a VPC endpoint, the source IP condition can fail to match, causing authorization errors.

## Solution Applied
I've updated the Terraform configuration with the following changes:

### 1. Fixed API Gateway Resource Policy
**File**: `main.tf` (lines 96-111)

**Before**:
```hcl
policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Principal = "*"
      Action = "execute-api:Invoke"
      Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      Condition = {
        IpAddress = {
          "aws:sourceIp" = var.allowed_cidr_blocks
        }
      }
    }
  ]
})
```

**After**:
```hcl
policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Principal = "*"
      Action = "execute-api:Invoke"
      Resource = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
      Condition = {
        StringEquals = {
          "aws:sourceVpce" = aws_vpc_endpoint.api_gateway.id
        }
      }
    }
  ]
})
```

### 2. Enhanced VPC Endpoint Policy
**File**: `main.tf` (lines 219-236)

Updated the VPC endpoint policy to be more specific and include IP-based restrictions at the VPC endpoint level while allowing the API Gateway to use VPC endpoint-based authorization.

### 3. Updated Documentation
- Added comprehensive troubleshooting section in README.md
- Included specific guidance for the authorization error
- Added debugging commands to help diagnose issues

## Next Steps

### 1. Apply the Changes
If you haven't deployed this yet, run:
```bash
./deploy.sh
```

If you already have the infrastructure deployed, update it:
```bash
terraform plan
terraform apply
```

### 2. Test the Fix
From within your VPC (e.g., from an EC2 instance), test the API:
```bash
curl -X GET "https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod/"
```

### 3. Verify Configuration
Check that your `terraform.tfvars` file has the correct values:
- `vpc_id`: Your actual VPC ID
- `subnet_ids`: Your private subnet IDs (should be in different AZs)
- `allowed_cidr_blocks`: CIDR blocks that include your source IPs

### 4. Troubleshooting
If you still encounter issues:

1. **Verify VPC Endpoint Status**:
   ```bash
   aws ec2 describe-vpc-endpoints --vpc-endpoint-ids YOUR_ENDPOINT_ID
   ```

2. **Check Security Group Rules**:
   ```bash
   aws ec2 describe-security-groups --group-ids YOUR_SECURITY_GROUP_ID
   ```

3. **Test DNS Resolution**:
   ```bash
   nslookup YOUR_API_ID.execute-api.us-east-1.amazonaws.com
   ```

4. **Check API Gateway Resource Policy**:
   ```bash
   aws apigateway get-resource-policy --rest-api-id YOUR_API_ID
   ```

## Key Points
- The fix changes from IP-based authorization to VPC endpoint-based authorization
- This is the recommended approach for private API Gateway endpoints
- The API remains secure and only accessible from within your VPC
- The VPC endpoint policy still includes IP restrictions as an additional security layer

## Security Benefits
- More reliable authorization for VPC endpoint access
- Maintains network-level isolation
- Prevents external internet access
- Provides clear audit trail through VPC endpoint identification

The authorization error should now be resolved, and your private API Gateway should be accessible from within your VPC.
