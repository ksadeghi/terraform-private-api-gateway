
#!/bin/bash

# Quick fix script for API Gateway authorization issues
# This script helps you test different policy types to resolve authorization errors

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

echo "=========================================="
echo "API Gateway Authorization Fix Script"
echo "=========================================="

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_error "terraform.tfvars file not found!"
    print_status "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    print_warning "Please edit terraform.tfvars with your actual VPC and subnet IDs before proceeding."
    exit 1
fi

print_header "Step 1: Current Configuration Check"
if grep -q "api_policy_type" terraform.tfvars; then
    CURRENT_POLICY=$(grep "api_policy_type" terraform.tfvars | cut -d'"' -f2)
    print_status "Current policy type: $CURRENT_POLICY"
else
    print_warning "No api_policy_type found in terraform.tfvars. Adding default 'combined' policy..."
    echo 'api_policy_type = "combined"' >> terraform.tfvars
    CURRENT_POLICY="combined"
fi

print_header "Step 2: Policy Options"
echo "Available policy types:"
echo "1. combined    - VPC endpoint + IP conditions (recommended)"
echo "2. ip_only     - IP-based conditions only (fallback)"
echo "3. vpc_endpoint - VPC endpoint condition only"
echo "4. open        - No restrictions (TESTING ONLY)"

echo ""
read -p "Enter policy type to try (1-4) or press Enter for current [$CURRENT_POLICY]: " choice

case $choice in
    1)
        NEW_POLICY="combined"
        ;;
    2)
        NEW_POLICY="ip_only"
        ;;
    3)
        NEW_POLICY="vpc_endpoint"
        ;;
    4)
        print_warning "WARNING: 'open' policy removes all security restrictions!"
        read -p "Are you sure you want to use the open policy? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            NEW_POLICY="open"
        else
            print_status "Cancelled. Using current policy."
            NEW_POLICY="$CURRENT_POLICY"
        fi
        ;;
    "")
        NEW_POLICY="$CURRENT_POLICY"
        ;;
    *)
        print_error "Invalid choice. Using current policy."
        NEW_POLICY="$CURRENT_POLICY"
        ;;
esac

print_header "Step 3: Updating Configuration"
if [ "$NEW_POLICY" != "$CURRENT_POLICY" ]; then
    print_status "Updating policy type to: $NEW_POLICY"
    sed -i "s/api_policy_type = \".*\"/api_policy_type = \"$NEW_POLICY\"/" terraform.tfvars
else
    print_status "Using current policy type: $NEW_POLICY"
fi

print_header "Step 4: Applying Terraform Changes"
print_status "Running terraform plan..."
terraform plan -var="api_policy_type=$NEW_POLICY"

echo ""
read -p "Apply these changes? (yes/no): " apply_confirm
if [ "$apply_confirm" = "yes" ]; then
    print_status "Applying changes..."
    terraform apply -var="api_policy_type=$NEW_POLICY" -auto-approve
    
    print_header "Step 5: Getting API Information"
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null || echo "")
    VPC_ENDPOINT_ID=$(terraform output -raw vpc_endpoint_id 2>/dev/null || echo "")
    
    if [ -n "$API_URL" ]; then
        print_status "API URL: $API_URL"
        print_status "VPC Endpoint ID: $VPC_ENDPOINT_ID"
        echo ""
        print_status "Test the API from within your VPC:"
        echo "curl -X GET \"$API_URL\""
        echo ""
        
        if [ "$NEW_POLICY" = "open" ]; then
            print_warning "SECURITY WARNING: You're using an open policy!"
            print_warning "Remember to change back to a secure policy after testing:"
            echo "./fix_authorization.sh"
        fi
    fi
    
    print_status "Changes applied successfully!"
else
    print_status "Changes cancelled."
fi

print_header "Troubleshooting Tips"
echo "If you still get authorization errors:"
echo "1. Verify you're testing from within the VPC"
echo "2. Check security group allows HTTPS (port 443)"
echo "3. Ensure your source IP is in allowed_cidr_blocks"
echo "4. Try the 'ip_only' policy if VPC endpoint conditions don't work"
echo "5. Use 'open' policy temporarily to test connectivity (then secure it)"
echo ""
echo "For detailed troubleshooting, see: TROUBLESHOOTING_STEPS.md"

