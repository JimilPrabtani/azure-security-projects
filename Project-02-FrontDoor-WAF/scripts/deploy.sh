#!/bin/bash
# =============================================================================
# Deploy Script — Azure Front Door with WAF Security Project
# =============================================================================
# Usage: ./deploy.sh [resource-group-name] [primary-location] [secondary-location]
# =============================================================================

set -euo pipefail

# Configuration
RESOURCE_GROUP="${1:-rg-frontdoor-security-project}"
LOCATION_PRIMARY="${2:-eastus}"
LOCATION_SECONDARY="${3:-westus}"
SUFFIX=$(openssl rand -hex 4)
PRIMARY_APP="webapp-fd-primary-$SUFFIX"
SECONDARY_APP="webapp-fd-secondary-$SUFFIX"
FD_NAME="fd-security-project-$SUFFIX"

echo "============================================"
echo " Azure Front Door + WAF Deployment"
echo "============================================"
echo "Resource Group     : $RESOURCE_GROUP"
echo "Primary Location   : $LOCATION_PRIMARY"
echo "Secondary Location : $LOCATION_SECONDARY"
echo "Front Door Name    : $FD_NAME"
echo "Primary App        : $PRIMARY_APP"
echo "Secondary App      : $SECONDARY_APP"
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
    --location "$LOCATION_PRIMARY" \
    --tags Project="AZ500-FrontDoor-WAF" Environment="Lab" \
    --output none

# Deploy ARM Template
echo "[3/4] Deploying ARM template (this may take 10-15 minutes)..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/../arm-templates/deploy-frontdoor.json"
PARAMS_FILE="$SCRIPT_DIR/../arm-templates/deploy-frontdoor.parameters.json"

az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMS_FILE" \
    --parameters \
        primaryWebAppName="$PRIMARY_APP" \
        secondaryWebAppName="$SECONDARY_APP" \
        frontDoorName="$FD_NAME" \
    --query "properties.outputs" \
    -o table

# Display Results
echo "[4/4] Deployment complete!"
echo ""

FD_HOSTNAME=$(az afd endpoint show \
    --resource-group "$RESOURCE_GROUP" \
    --profile-name "$FD_NAME" \
    --endpoint-name "endpoint-security" \
    --query hostName -o tsv 2>/dev/null || echo "Pending")

echo "============================================"
echo " Deployment Outputs"
echo "============================================"
echo "Front Door URL     : https://$FD_HOSTNAME"
echo "Primary App URL    : https://$PRIMARY_APP.azurewebsites.net"
echo "Secondary App URL  : https://$SECONDARY_APP.azurewebsites.net"
echo ""
echo "Next Steps:"
echo "  1. Configure backend access restrictions: see Step 6 in README.md"
echo "  2. Configure monitoring: see Step 7 in README.md"
echo "  3. Run WAF tests: see Step 8 in README.md"
echo "============================================"
