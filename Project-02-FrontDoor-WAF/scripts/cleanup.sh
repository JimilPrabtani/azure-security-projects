#!/bin/bash
# =============================================================================
# Cleanup Script — Delete all resources from the Front Door project
# =============================================================================
# Usage: ./cleanup.sh [resource-group-name]
# =============================================================================

set -euo pipefail

RESOURCE_GROUP="${1:-rg-frontdoor-security-project}"

echo "============================================"
echo " Cleanup — Front Door + WAF Project"
echo "============================================"
echo "Resource Group: $RESOURCE_GROUP"
echo ""

# Confirm deletion
read -p "Are you sure you want to delete all resources in '$RESOURCE_GROUP'? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo "Deleting resource group '$RESOURCE_GROUP'..."
az group delete --name "$RESOURCE_GROUP" --yes --no-wait

echo ""
echo "Resource group deletion initiated (runs in background)."
echo "Verify with: az group show --name $RESOURCE_GROUP 2>/dev/null || echo 'Deleted'"

# Clean up custom role if it exists
echo "Cleaning up custom role 'Front Door Security Operator'..."
az role definition delete --name "Front Door Security Operator" 2>/dev/null && echo "Custom role deleted." || echo "No custom role found."

echo ""
echo "Cleanup complete!"
