


#!/bin/bash

# Script to help you find your VPC and subnet IDs

echo "=== Finding Your VPC and Subnet Information ==="
echo ""

echo "Available VPCs in us-east-1:"
aws ec2 describe-vpcs --region us-east-1 --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table 2>/dev/null || echo "Error: Could not list VPCs. Check AWS CLI configuration."

echo ""
echo "Available Subnets in us-east-1:"
aws ec2 describe-subnets --region us-east-1 --query 'Subnets[*].[SubnetId,VpcId,CidrBlock,AvailabilityZone,Tags[?Key==`Name`].Value|[0]]' --output table 2>/dev/null || echo "Error: Could not list subnets. Check AWS CLI configuration."

echo ""
echo "=== Instructions ==="
echo "1. Choose a VPC ID from the list above"
echo "2. Choose 2 subnet IDs that belong to that VPC"
echo "3. Update terraform.tfvars with these values"
echo ""
echo "Example terraform.tfvars update:"
echo 'vpc_id = "vpc-0123456789abcdef0"'
echo 'subnet_ids = ['
echo '  "subnet-0123456789abcdef0",'
echo '  "subnet-0987654321fedcba0"'
echo ']'


