#!/bin/bash
# =============================================================================
# Cleanup Script — Delete all IAM & RBAC project resources
# =============================================================================
# Usage: ./cleanup.sh [resource-group-name]
# =============================================================================

set -euo pipefail

RESOURCE_GROUP="${1:-rg-iam-security-project}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AD_DOMAIN=$(az ad signed-in-user show --query userPrincipalName -o tsv | cut -d'@' -f2)

echo "============================================"
echo " Cleanup — IAM & RBAC Security Project"
echo "============================================"
echo "Resource Group : $RESOURCE_GROUP"
echo "Azure AD Domain: $AD_DOMAIN"
echo ""

# Confirm deletion
read -p "This will delete test users, groups, custom roles, and the resource group. Continue? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete resource group
echo "[1/4] Deleting resource group..."
az group delete --name "$RESOURCE_GROUP" --yes --no-wait 2>/dev/null && echo "  Resource group deletion initiated." || echo "  Resource group not found."

# Delete test users
echo "[2/4] Deleting test users..."
for USER in "lab-secops" "lab-devops" "lab-reader"; do
    az ad user delete --id "${USER}@${AD_DOMAIN}" 2>/dev/null && echo "  Deleted ${USER}@${AD_DOMAIN}" || echo "  ${USER}@${AD_DOMAIN} not found."
done

# Delete security groups
echo "[3/4] Deleting security groups..."
for GROUP in "SG-Azure-Admins" "SG-Security-Operators" "SG-DevOps-Team" "SG-Readers"; do
    az ad group delete --group "$GROUP" 2>/dev/null && echo "  Deleted $GROUP" || echo "  $GROUP not found."
done

# Delete custom roles and service principal
echo "[4/4] Deleting custom roles and service principal..."
for ROLE in "Security Operator" "DevOps Deployer"; do
    az role definition delete --name "$ROLE" 2>/dev/null && echo "  Deleted role: $ROLE" || echo "  Role '$ROLE' not found."
done

SP_ID=$(az ad sp list --display-name "sp-cicd-pipeline" --query "[0].id" -o tsv 2>/dev/null)
if [ -n "$SP_ID" ]; then
    az ad sp delete --id "$SP_ID" 2>/dev/null && echo "  Deleted service principal: sp-cicd-pipeline"
else
    echo "  Service principal 'sp-cicd-pipeline' not found."
fi

echo ""
echo "Cleanup complete!"
echo "Verify in Azure Portal that all resources are deleted."
