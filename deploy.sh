#!/bin/bash

# Deployment script for Private API Gateway with Lambda
# This script helps deploy and test the private API Gateway setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_error "terraform.tfvars file not found!"
    print_status "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    print_warning "Please edit terraform.tfvars with your actual VPC and subnet IDs before proceeding."
    exit 1
fi

# Check if required variables are set
if grep -q "vpc-xxxxxxxxx" terraform.tfvars; then
    print_error "Please update terraform.tfvars with your actual VPC ID and subnet IDs"
    exit 1
fi

print_status "Starting Terraform deployment..."

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Validate configuration
print_status "Validating Terraform configuration..."
terraform validate

# Plan deployment
print_status "Creating Terraform plan..."
terraform plan -out=tfplan

# Apply deployment
print_status "Applying Terraform configuration..."
terraform apply tfplan

# Get outputs
print_status "Deployment completed! Getting outputs..."
API_ID=$(terraform output -raw api_gateway_id 2>/dev/null || echo "")
VPC_ENDPOINT_ID=$(terraform output -raw vpc_endpoint_id 2>/dev/null || echo "")
API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")

if [ -n "$API_ID" ]; then
    print_status "API Gateway ID: $API_ID"
fi

if [ -n "$VPC_ENDPOINT_ID" ]; then
    print_status "VPC Endpoint ID: $VPC_ENDPOINT_ID"
fi

if [ -n "$API_URL" ]; then
    print_status "API URL: $API_URL"
    print_warning "Remember: This API is only accessible from within your VPC!"
    
    echo ""
    print_status "To test the API from within your VPC, run:"
    echo "curl -X GET \"$API_URL\""
    echo ""
    print_status "If you get authorization errors, check the troubleshooting section in README.md"
else
    print_warning "Could not retrieve API URL from Terraform outputs"
fi

print_status "Deployment script completed successfully!"
