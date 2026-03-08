#!/bin/bash
# =============================================================================
# Deploy Script — Azure Application Gateway with WAF Security Project
# =============================================================================
# Usage: ./deploy.sh [resource-group-name] [location]
# =============================================================================

set -euo pipefail

# Configuration
RESOURCE_GROUP="${1:-rg-appgw-security-project}"
LOCATION="${2:-eastus}"
WEB_APP_NAME="webapp-security-$(openssl rand -hex 4)"

echo "============================================"
echo " Azure Application Gateway + WAF Deployment"
echo "============================================"
echo "Resource Group : $RESOURCE_GROUP"
echo "Location       : $LOCATION"
echo "Web App Name   : $WEB_APP_NAME"
echo "============================================"

# Verify Azure CLI login
echo "[1/4] Verifying Azure CLI login..."
az account show --query "{Subscription:name, Id:id}" -o table || {
    echo "ERROR: Not logged in. Run 'az login' first."
    exit 1
}

# Create Resource Group
echo "[2/4] Creating resource group..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --tags Project="AZ500-AppGW-WAF" Environment="Lab" \
    --output none

# Deploy ARM Template
echo "[3/4] Deploying ARM template (this may take 15-25 minutes)..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../arm-templates/deploy-appgw.json"
PARAMS_FILE="$SCRIPT_DIR/../arm-templates/deploy-appgw.parameters.json"

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMS_FILE" \
    --parameters webAppName="$WEB_APP_NAME" \
    --query "properties.outputs" \
    -o table

# Display Results
echo "[4/4] Deployment complete!"
echo ""
echo "============================================"
echo " Deployment Outputs"
echo "============================================"

APPGW_IP=$(az network public-ip show \
    --resource-group "$RESOURCE_GROUP" \
    --name "pip-appgw" \
    --query ipAddress -o tsv 2>/dev/null || echo "Pending")

echo "Application Gateway IP : $APPGW_IP"
echo "Web App URL            : https://$WEB_APP_NAME.azurewebsites.net"
echo "Test URL               : http://$APPGW_IP"
echo ""
echo "Next Steps:"
echo "  1. Configure Key Vault: see Step 7 in README.md"
echo "  2. Configure Monitoring: see Step 8 in README.md"
echo "  3. Run WAF tests: see Step 9 in README.md"
echo "============================================"
