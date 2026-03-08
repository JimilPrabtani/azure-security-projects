# 🔐 Project 03 — IAM & RBAC Security Hardening

> **Role:** Senior Azure Security Architect  
> **AZ-500 Domains:** Manage Identity and Access · Implement Platform Protection  
> **Estimated Time:** 2–3 hours  
> **Cost:** Fully free (uses only Azure AD free features and built-in RBAC)

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Architecture Diagram](#-architecture-diagram)
3. [Prerequisites](#-prerequisites)
4. [Step 1 — Azure AD Security Baseline](#step-1--azure-ad-security-baseline)
5. [Step 2 — RBAC Role Assignments & Custom Roles](#step-2--rbac-role-assignments--custom-roles)
6. [Step 3 — Managed Identities](#step-3--managed-identities)
7. [Step 4 — Conditional Access Policies](#step-4--conditional-access-policies)
8. [Step 5 — Multi-Factor Authentication (MFA)](#step-5--multi-factor-authentication-mfa)
9. [Step 6 — Privileged Identity Management (PIM)](#step-6--privileged-identity-management-pim)
10. [Step 7 — Service Principal Security](#step-7--service-principal-security)
11. [Step 8 — Audit & Monitoring](#step-8--audit--monitoring)
12. [Step 9 — Validation & Testing](#step-9--validation--testing)
13. [Step 10 — Cleanup](#step-10--cleanup)
14. [Free-Tier Alternatives](#-free-tier-alternatives)
15. [Skills Demonstrated](#-skills-demonstrated)

---

## 🎯 Project Overview

This project implements a **comprehensive Identity and Access Management (IAM) security strategy** using Azure Active Directory (Azure AD / Microsoft Entra ID) and Azure RBAC. It demonstrates enterprise-grade identity security following **Zero Trust principles**.

### What You Will Configure

| Component | Purpose |
|-----------|---------|
| Azure AD Users & Groups | Identity management and group-based access |
| RBAC Custom Roles | Least-privilege access with custom permissions |
| Managed Identities | Credential-free service-to-service authentication |
| Conditional Access | Risk-based access policies (Azure AD Premium P2 or free alternatives) |
| MFA Configuration | Multi-factor authentication enforcement |
| PIM | Just-in-time privileged access (Premium P2 or free alternatives) |
| Service Principals | Secure automation and CI/CD access |
| Audit Logging | Identity event monitoring and alerting |

### Zero Trust Principles Applied

| Principle | Implementation |
|-----------|---------------|
| **Verify explicitly** | Conditional Access + MFA on every sign-in |
| **Use least privilege** | Custom RBAC roles + PIM for just-in-time access |
| **Assume breach** | Audit logging + sign-in risk monitoring |

---

## 🏗️ Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     AZURE ACTIVE DIRECTORY (ENTRA ID)                   │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                    IDENTITY LAYER                                │    │
│  │                                                                  │    │
│  │  ┌─────────────┐  ┌──────────────┐  ┌───────────────────────┐   │    │
│  │  │   Users      │  │   Groups     │  │  Service Principals  │   │    │
│  │  │  • Admins    │  │  • SG-Admins │  │  • CI/CD Pipeline    │   │    │
│  │  │  • Operators │  │  • SG-Ops    │  │  • App Registration  │   │    │
│  │  │  • Readers   │  │  • SG-Dev    │  │  • Managed Identity  │   │    │
│  │  └─────────────┘  └──────────────┘  └───────────────────────┘   │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                    │                                     │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                    POLICY LAYER                                  │    │
│  │                                                                  │    │
│  │  ┌────────────────┐  ┌─────────────┐  ┌──────────────────────┐  │    │
│  │  │ Conditional    │  │    MFA      │  │  PIM (Just-in-Time) │  │    │
│  │  │ Access         │  │  Required   │  │  • Time-limited     │  │    │
│  │  │ • Location     │  │  for all    │  │  • Approval-based   │  │    │
│  │  │ • Device       │  │  admin      │  │  • Audit logged     │  │    │
│  │  │ • Risk level   │  │  access     │  │                      │  │    │
│  │  └────────────────┘  └─────────────┘  └──────────────────────┘  │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                    │                                     │
└────────────────────────────────────┼─────────────────────────────────────┘
                                     │
                                     ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                        AZURE RESOURCES                                   │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                    RBAC LAYER                                    │    │
│  │                                                                  │    │
│  │  Subscription Level                                              │    │
│  │  ├── Reader (SG-Readers group)                                   │    │
│  │  │                                                               │    │
│  │  Resource Group Level                                            │    │
│  │  ├── Custom Role: "Security Operator" (SG-Ops group)             │    │
│  │  ├── Custom Role: "WAF Operator" (SG-Security group)             │    │
│  │  │                                                               │    │
│  │  Resource Level                                                  │    │
│  │  ├── Key Vault Secrets User (Managed Identity)                   │    │
│  │  ├── Key Vault Administrator (SG-Admins group)                   │    │
│  │  └── Contributor (CI/CD Service Principal)                       │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │                    AUDIT LAYER                                   │    │
│  │                                                                  │    │
│  │  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────┐  │    │
│  │  │ Sign-in Logs    │  │ Audit Logs       │  │ Activity Logs  │  │    │
│  │  │ • Who logged in │  │ • What changed   │  │ • RBAC changes │  │    │
│  │  │ • MFA status    │  │ • Role changes   │  │ • Deployments  │  │    │
│  │  │ • Risk events   │  │ • Policy updates │  │ • Deletions    │  │    │
│  │  └─────────────────┘  └──────────────────┘  └────────────────┘  │    │
│  └──────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## ✅ Prerequisites

- **Azure Account** — Free account or Azure for Students
- **Azure CLI** — v2.50+ installed
- **Azure AD Permissions** — Global Administrator or User Administrator role (for creating users/groups)
- **Note:** Some features require Azure AD Premium P2 (free trials available; alternatives documented)

### Login to Azure

```bash
az login
az account show --query "{Subscription:name, SubscriptionId:id, TenantId:tenantId}" -o table
```

---

## Step 1 — Azure AD Security Baseline

### 1.1 Set Environment Variables

```bash
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export TENANT_ID=$(az account show --query tenantId -o tsv)
export RESOURCE_GROUP="rg-iam-security-project"
export LOCATION="eastus"
```

### 1.2 Create Resource Group for IAM Project

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags Project="AZ500-IAM-RBAC" Environment="Lab" ManagedBy="AzureCLI"
```

### 1.3 Create Security Groups

```bash
# Create security groups for role-based access
az ad group create \
  --display-name "SG-Azure-Admins" \
  --mail-nickname "sg-azure-admins" \
  --description "Azure subscription administrators"

az ad group create \
  --display-name "SG-Security-Operators" \
  --mail-nickname "sg-security-operators" \
  --description "Security operations team — WAF and security management"

az ad group create \
  --display-name "SG-DevOps-Team" \
  --mail-nickname "sg-devops-team" \
  --description "DevOps team — deployment and operations"

az ad group create \
  --display-name "SG-Readers" \
  --mail-nickname "sg-readers" \
  --description "Read-only access to Azure resources"

# List created groups
az ad group list \
  --filter "startswith(displayName, 'SG-')" \
  --query "[].{Name:displayName, ObjectId:id}" \
  -o table
```

### 1.4 Create Test Users (Lab Only)

```bash
# Get your Azure AD domain
export AD_DOMAIN=$(az ad signed-in-user show --query userPrincipalName -o tsv | cut -d'@' -f2)

# Create test users (use a strong password — this is for lab only)
# Note: Replace with your actual Azure AD domain

# Security Operator user
az ad user create \
  --display-name "Lab Security Operator" \
  --user-principal-name "lab-secops@$AD_DOMAIN" \
  --password "LabP@ssw0rd2026!" \
  --force-change-password-next-sign-in true

# DevOps user
az ad user create \
  --display-name "Lab DevOps Engineer" \
  --user-principal-name "lab-devops@$AD_DOMAIN" \
  --password "LabP@ssw0rd2026!" \
  --force-change-password-next-sign-in true

# Reader user
az ad user create \
  --display-name "Lab Reader" \
  --user-principal-name "lab-reader@$AD_DOMAIN" \
  --password "LabP@ssw0rd2026!" \
  --force-change-password-next-sign-in true

echo "Test users created. Users must change password on first sign-in."
```

> **⚠️ Security Note:** These test users use a placeholder password that must be changed on first sign-in. In production, use Azure AD B2C or federated identities. Delete test users during cleanup.

### 1.5 Add Users to Groups

```bash
# Get user and group IDs
export SECOPS_USER_ID=$(az ad user show --id "lab-secops@$AD_DOMAIN" --query id -o tsv)
export DEVOPS_USER_ID=$(az ad user show --id "lab-devops@$AD_DOMAIN" --query id -o tsv)
export READER_USER_ID=$(az ad user show --id "lab-reader@$AD_DOMAIN" --query id -o tsv)

export ADMINS_GROUP_ID=$(az ad group show --group "SG-Azure-Admins" --query id -o tsv)
export SECOPS_GROUP_ID=$(az ad group show --group "SG-Security-Operators" --query id -o tsv)
export DEVOPS_GROUP_ID=$(az ad group show --group "SG-DevOps-Team" --query id -o tsv)
export READERS_GROUP_ID=$(az ad group show --group "SG-Readers" --query id -o tsv)

# Add users to appropriate groups
az ad group member add --group $SECOPS_GROUP_ID --member-id $SECOPS_USER_ID
az ad group member add --group $DEVOPS_GROUP_ID --member-id $DEVOPS_USER_ID
az ad group member add --group $READERS_GROUP_ID --member-id $READER_USER_ID

# Verify group memberships
echo "--- SG-Security-Operators ---"
az ad group member list --group "SG-Security-Operators" --query "[].displayName" -o tsv
echo "--- SG-DevOps-Team ---"
az ad group member list --group "SG-DevOps-Team" --query "[].displayName" -o tsv
echo "--- SG-Readers ---"
az ad group member list --group "SG-Readers" --query "[].displayName" -o tsv
```

---

## Step 2 — RBAC Role Assignments & Custom Roles

### 2.1 Create Custom Role: Security Operator

```bash
cat > /tmp/security-operator-role.json << EOF
{
  "Name": "Security Operator",
  "Description": "Can manage security resources including WAF, NSG, and Key Vault policies. Cannot modify IAM or networking.",
  "Actions": [
    "Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/*",
    "Microsoft.Network/FrontDoorWebApplicationFirewallPolicies/*",
    "Microsoft.Network/networkSecurityGroups/read",
    "Microsoft.Network/networkSecurityGroups/securityRules/read",
    "Microsoft.KeyVault/vaults/read",
    "Microsoft.KeyVault/vaults/secrets/read",
    "Microsoft.Insights/metrics/read",
    "Microsoft.Insights/diagnosticSettings/read",
    "Microsoft.Insights/logDefinitions/read",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Security/*/read"
  ],
  "NotActions": [
    "Microsoft.Authorization/*/write",
    "Microsoft.Authorization/*/delete"
  ],
  "AssignableScopes": [
    "/subscriptions/$SUBSCRIPTION_ID"
  ]
}
EOF

az role definition create --role-definition /tmp/security-operator-role.json
echo "Custom role 'Security Operator' created."
```

### 2.2 Create Custom Role: DevOps Deployer

```bash
cat > /tmp/devops-deployer-role.json << EOF
{
  "Name": "DevOps Deployer",
  "Description": "Can deploy and manage App Services and related resources. Cannot modify IAM, networking, or security policies.",
  "Actions": [
    "Microsoft.Web/sites/*",
    "Microsoft.Web/serverfarms/*",
    "Microsoft.Web/certificates/*",
    "Microsoft.Resources/deployments/*",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Insights/metrics/read",
    "Microsoft.Insights/diagnosticSettings/read"
  ],
  "NotActions": [
    "Microsoft.Authorization/*/write",
    "Microsoft.Authorization/*/delete",
    "Microsoft.Network/*/write",
    "Microsoft.Network/*/delete"
  ],
  "AssignableScopes": [
    "/subscriptions/$SUBSCRIPTION_ID"
  ]
}
EOF

az role definition create --role-definition /tmp/devops-deployer-role.json
echo "Custom role 'DevOps Deployer' created."
```

### 2.3 Assign Roles to Groups

```bash
# Assign Security Operator to SG-Security-Operators at resource group level
az role assignment create \
  --assignee $SECOPS_GROUP_ID \
  --role "Security Operator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Assign DevOps Deployer to SG-DevOps-Team at resource group level
az role assignment create \
  --assignee $DEVOPS_GROUP_ID \
  --role "DevOps Deployer" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Assign Reader to SG-Readers at subscription level
az role assignment create \
  --assignee $READERS_GROUP_ID \
  --role "Reader" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

echo "Role assignments completed."
```

### 2.4 Verify Role Assignments

```bash
# List all role assignments in the resource group
echo "=== Resource Group Role Assignments ==="
az role assignment list \
  --resource-group $RESOURCE_GROUP \
  --query "[].{Principal:principalName, Role:roleDefinitionName, PrincipalType:principalType}" \
  -o table

# List custom role definitions
echo ""
echo "=== Custom Role Definitions ==="
az role definition list \
  --custom-role-only true \
  --query "[].{Name:roleName, Description:description}" \
  -o table
```

> **📝 RBAC Best Practices Applied:**
> - **Group-based assignment** — Roles assigned to groups, not individual users
> - **Least privilege** — Each role has only the permissions needed
> - **NotActions** — Explicitly deny dangerous operations
> - **Scoped assignment** — Roles scoped to resource group (not subscription) where possible
> - **Custom roles** — Built for specific job functions

---

## Step 3 — Managed Identities

### 3.1 Create a Resource with System-Assigned Managed Identity

```bash
# Create a sample App Service with Managed Identity
export MI_APP_NAME="webapp-mi-demo-$(openssl rand -hex 4)"
export MI_APP_PLAN="asp-mi-demo"

az appservice plan create \
  --resource-group $RESOURCE_GROUP \
  --name $MI_APP_PLAN \
  --sku F1 \
  --is-linux

az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $MI_APP_PLAN \
  --name $MI_APP_NAME \
  --runtime "NODE:18-lts"

# Enable system-assigned managed identity
az webapp identity assign \
  --resource-group $RESOURCE_GROUP \
  --name $MI_APP_NAME

export MI_PRINCIPAL_ID=$(az webapp identity show \
  --resource-group $RESOURCE_GROUP \
  --name $MI_APP_NAME \
  --query principalId -o tsv)

echo "Managed Identity Principal ID: $MI_PRINCIPAL_ID"
```

### 3.2 Create User-Assigned Managed Identity

```bash
export UAMI_NAME="uami-security-project"

az identity create \
  --resource-group $RESOURCE_GROUP \
  --name $UAMI_NAME \
  --location $LOCATION

export UAMI_PRINCIPAL_ID=$(az identity show \
  --resource-group $RESOURCE_GROUP \
  --name $UAMI_NAME \
  --query principalId -o tsv)

export UAMI_CLIENT_ID=$(az identity show \
  --resource-group $RESOURCE_GROUP \
  --name $UAMI_NAME \
  --query clientId -o tsv)

echo "User-Assigned MI Principal ID: $UAMI_PRINCIPAL_ID"
echo "User-Assigned MI Client ID: $UAMI_CLIENT_ID"
```

### 3.3 Create Key Vault and Grant Managed Identity Access

```bash
export KV_NAME="kv-iam-demo-$(openssl rand -hex 4)"

az keyvault create \
  --resource-group $RESOURCE_GROUP \
  --name $KV_NAME \
  --location $LOCATION \
  --sku standard \
  --enable-rbac-authorization true

# Grant Key Vault Secrets User to the system-assigned managed identity
az role assignment create \
  --assignee $MI_PRINCIPAL_ID \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KV_NAME"

# Grant Key Vault Secrets User to the user-assigned managed identity
az role assignment create \
  --assignee $UAMI_PRINCIPAL_ID \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KV_NAME"

echo "Managed identities granted Key Vault access."
```

### 3.4 Store and Access Secrets via Managed Identity

```bash
# Store a secret (as admin)
export CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv)
az role assignment create \
  --assignee $CURRENT_USER_ID \
  --role "Key Vault Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KV_NAME"

az keyvault secret set \
  --vault-name $KV_NAME \
  --name "DatabaseConnectionString" \
  --value "Server=myserver.database.windows.net;Database=mydb;"

# Configure App Service to use Key Vault reference
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $MI_APP_NAME \
  --settings "DB_CONN=@Microsoft.KeyVault(VaultName=$KV_NAME;SecretName=DatabaseConnectionString)"

echo "App Service configured to access Key Vault via Managed Identity."
```

> **📝 Managed Identity Benefits:**
> - No credentials stored in code or configuration
> - Automatic credential rotation by Azure
> - Audit trail of all access in Azure AD logs
> - No risk of credential exposure in source control

---

## Step 4 — Conditional Access Policies

> **⚠️ Requires Azure AD Premium P2.** Free alternatives documented below each step.

### 4.1 Conditional Access: Require MFA for Admin Roles

**Azure Portal Steps** (Conditional Access requires Portal):

1. Navigate to **Microsoft Entra ID** → **Security** → **Conditional Access**
2. Click **+ New policy**
3. Configure:
   - **Name:** `Require MFA for Admins`
   - **Users:** Include → Select roles → Global Administrator, Security Administrator, User Administrator
   - **Cloud apps:** All cloud apps
   - **Conditions:** None (apply always)
   - **Grant:** Require multi-factor authentication
   - **Session:** Sign-in frequency: 1 hour
4. Set policy to **Report-only** first, then **On** after testing

### 4.2 Conditional Access: Block Legacy Authentication

1. Navigate to **Conditional Access** → **+ New policy**
2. Configure:
   - **Name:** `Block Legacy Authentication`
   - **Users:** All users
   - **Cloud apps:** All cloud apps
   - **Conditions:** Client apps → Exchange ActiveSync, Other clients
   - **Grant:** Block access
3. Enable policy

### 4.3 Conditional Access: Require Compliant Device for Sensitive Apps

1. Navigate to **Conditional Access** → **+ New policy**
2. Configure:
   - **Name:** `Require Compliant Device for Azure Portal`
   - **Users:** All users (exclude break-glass account)
   - **Cloud apps:** Microsoft Azure Management
   - **Conditions:** None
   - **Grant:** Require device to be marked as compliant (or Require Hybrid Azure AD Join)
3. Enable policy

### Free-Tier Alternative: Security Defaults

```bash
# If you don't have Azure AD Premium P2, enable Security Defaults instead
# This provides baseline MFA for all users

# Check current security defaults status via Azure Portal:
# Microsoft Entra ID → Properties → Manage security defaults

# Or via Microsoft Graph API (requires appropriate permissions):
# az rest --method GET \
#   --url "https://graph.microsoft.com/v1.0/policies/identitySecurityDefaultsEnforcementPolicy"

echo "For free-tier: Enable Security Defaults in Azure AD Properties."
echo "This requires MFA for all admins and users when needed."
```

---

## Step 5 — Multi-Factor Authentication (MFA)

### 5.1 Enable Per-User MFA (Free Tier)

**Azure Portal Steps:**

1. Navigate to **Microsoft Entra ID** → **Users** → **Per-user MFA**
2. Select lab users
3. Click **Enable**
4. Users will be prompted to set up MFA on next sign-in

### 5.2 Verify MFA Status

```bash
# Check MFA registration status (requires MS Graph API permissions)
# Free alternative: Check via Azure Portal → Users → Per-user MFA

echo "Verify MFA status in Azure Portal:"
echo "Microsoft Entra ID → Users → Per-user MFA"
echo ""
echo "All admin accounts should show MFA status: Enforced"
```

### 5.3 MFA Methods Configuration

**Configure allowed MFA methods via Azure Portal:**

1. Navigate to **Microsoft Entra ID** → **Security** → **Authentication methods**
2. Recommended settings:
   - ✅ Microsoft Authenticator (push notifications)
   - ✅ FIDO2 security keys
   - ✅ Temporary Access Pass (for onboarding)
   - ❌ SMS (less secure; disable if possible)
   - ❌ Voice call (less secure; disable if possible)

> **📝 Best Practice:** Use phishing-resistant MFA methods (Authenticator, FIDO2) over SMS/Voice whenever possible.

---

## Step 6 — Privileged Identity Management (PIM)

> **⚠️ Requires Azure AD Premium P2.** Free alternatives documented below.

### 6.1 Configure PIM for Azure Roles (Portal Steps)

1. Navigate to **Microsoft Entra ID** → **Identity Governance** → **Privileged Identity Management**
2. Click **Azure resources** → Select your subscription
3. For each privileged role (Contributor, Owner, Security Admin):
   - Click the role → **Settings**
   - Set **Maximum activation duration:** 4 hours
   - **Require justification:** Yes
   - **Require approval:** Yes (for Owner role)
   - **Require MFA:** Yes
   - **Notification:** Send email to admins on activation

### 6.2 Make Roles Eligible (Not Permanently Assigned)

1. In PIM → **Azure resources** → Select role (e.g., Contributor)
2. Click **Add assignments**
3. Select the SG-DevOps-Team group
4. Assignment type: **Eligible** (not Active)
5. Duration: 30 days (must re-request after expiry)

### 6.3 Free-Tier Alternative: Manual JIT Process

```bash
# If PIM is not available, implement a manual just-in-time process:

# 1. Assign roles only when needed (via script)
# Example: Grant temporary Contributor access for 4 hours
grant_temporary_access() {
    local ASSIGNEE=$1
    local ROLE=$2
    local SCOPE=$3
    local HOURS=${4:-4}

    echo "Granting '$ROLE' to $ASSIGNEE for $HOURS hours..."

    az role assignment create \
      --assignee "$ASSIGNEE" \
      --role "$ROLE" \
      --scope "$SCOPE"

    echo "Access granted. Set a reminder to revoke in $HOURS hours."
    echo "Revoke command:"
    echo "  az role assignment delete --assignee '$ASSIGNEE' --role '$ROLE' --scope '$SCOPE'"
}

# Usage:
# grant_temporary_access "lab-devops@yourdomain.com" "Contributor" \
#   "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" 4

echo "Manual JIT process defined. Use grant_temporary_access function for ad-hoc access."
```

### 6.4 Create Access Review Reminder

```bash
# Free alternative to PIM access reviews: scheduled script
cat > /tmp/review-access.sh << 'SCRIPT'
#!/bin/bash
echo "=== Monthly RBAC Access Review ==="
echo "Date: $(date)"
echo ""
echo "--- Subscription-Level Assignments ---"
az role assignment list \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --query "[?principalType=='User'].{User:principalName, Role:roleDefinitionName, Scope:scope}" \
  -o table

echo ""
echo "--- Custom Role Assignments ---"
az role assignment list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{Principal:principalName, Role:roleDefinitionName, Type:principalType}" \
  -o table

echo ""
echo "Review each assignment. Remove any that are no longer needed."
SCRIPT

chmod +x /tmp/review-access.sh
echo "Access review script created at /tmp/review-access.sh"
```

---

## Step 7 — Service Principal Security

### 7.1 Create Service Principal for CI/CD

```bash
export SP_NAME="sp-cicd-pipeline"

# Create service principal with Contributor role scoped to resource group
az ad sp create-for-rbac \
  --name $SP_NAME \
  --role "DevOps Deployer" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --years 1

echo ""
echo "⚠️  IMPORTANT: Save the output above securely!"
echo "The password/secret is shown only once."
echo "Store it in Azure Key Vault or your CI/CD platform's secret store."
```

### 7.2 Configure Credential Rotation

```bash
# List current credentials and their expiry
az ad sp credential list \
  --id $SP_NAME \
  --query "[].{KeyId:keyId, StartDate:startDateTime, EndDate:endDateTime}" \
  -o table

echo ""
echo "Best Practice: Rotate service principal credentials every 90 days."
echo "Better: Use workload identity federation (OIDC) for GitHub Actions — no secrets needed."
```

### 7.3 Configure Federated Credentials (Passwordless CI/CD)

```bash
# For GitHub Actions — use OIDC federation instead of secrets
# This eliminates the need for stored credentials entirely

# Get the Service Principal object ID
export SP_OBJECT_ID=$(az ad sp list --display-name $SP_NAME --query "[0].id" -o tsv)

# Create federated credential for GitHub Actions
# Replace with your actual GitHub org/repo
# az ad app federated-credential create \
#   --id $SP_OBJECT_ID \
#   --parameters '{
#     "name": "github-actions-main",
#     "issuer": "https://token.actions.githubusercontent.com",
#     "subject": "repo:YourGitHubOrg/YourRepo:ref:refs/heads/main",
#     "audiences": ["api://AzureADTokenExchange"]
#   }'

echo "Federated credentials enable passwordless CI/CD authentication."
echo "Configure with your actual GitHub repository details."
```

> **📝 Service Principal Best Practices:**
> - Scope to minimum required resources (resource group, not subscription)
> - Use custom roles (DevOps Deployer) instead of broad built-in roles
> - Rotate credentials every 90 days
> - Prefer federated credentials (OIDC) over stored secrets
> - Monitor service principal sign-in logs

---

## Step 8 — Audit & Monitoring

### 8.1 View Azure AD Sign-in Logs

```bash
# View recent sign-in activity (Azure AD Premium or free limited view)
# Via Azure Portal: Microsoft Entra ID → Sign-in logs

# Via CLI (limited to Activity Log for free tier):
az monitor activity-log list \
  --resource-group $RESOURCE_GROUP \
  --max-events 20 \
  --query "[].{Time:eventTimestamp, Caller:caller, Operation:operationName.localizedValue, Status:status.localizedValue}" \
  -o table
```

### 8.2 Monitor RBAC Changes

```bash
# View role assignment changes in Activity Log
az monitor activity-log list \
  --resource-group $RESOURCE_GROUP \
  --max-events 50 \
  --query "[?contains(operationName.value, 'roleAssignments')].{Time:eventTimestamp, Caller:caller, Operation:operationName.localizedValue, Status:status.localizedValue}" \
  -o table
```

### 8.3 Create Alert for RBAC Changes

```bash
# Alert when role assignments are modified
az monitor activity-log alert create \
  --resource-group $RESOURCE_GROUP \
  --name "RBAC-Change-Alert" \
  --description "Alert when RBAC role assignments are created, updated, or deleted" \
  --condition category=Administrative and \
  operationName=Microsoft.Authorization/roleAssignments/write \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### 8.4 Create Alert for Key Vault Access

```bash
# Alert on Key Vault secret access
az monitor activity-log alert create \
  --resource-group $RESOURCE_GROUP \
  --name "KeyVault-Access-Alert" \
  --description "Alert when Key Vault secrets are accessed or modified" \
  --condition category=Administrative and \
  resourceType=Microsoft.KeyVault/vaults \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
```

### 8.5 Sample KQL Queries for Identity Monitoring

```kql
// Failed sign-in attempts (Azure AD Premium required for SigninLogs)
SigninLogs
| where ResultType != "0"
| project TimeGenerated, UserPrincipalName, AppDisplayName, ResultDescription, IPAddress, Location
| order by TimeGenerated desc

// Role assignment changes
AzureActivity
| where OperationNameValue contains "roleAssignments"
| project TimeGenerated, Caller, OperationNameValue, ActivityStatusValue
| order by TimeGenerated desc

// Service principal sign-ins
AADServicePrincipalSignInLogs
| project TimeGenerated, ServicePrincipalName, IPAddress, ResourceDisplayName, ResultType
| order by TimeGenerated desc

// Users with multiple failed sign-ins (potential brute force)
SigninLogs
| where ResultType != "0"
| summarize FailedCount = count() by UserPrincipalName, IPAddress
| where FailedCount > 5
| order by FailedCount desc
```

---

## Step 9 — Validation & Testing

### 9.1 Verify Group Memberships

```bash
echo "=== Security Groups ==="
for GROUP in "SG-Azure-Admins" "SG-Security-Operators" "SG-DevOps-Team" "SG-Readers"; do
    echo ""
    echo "--- $GROUP ---"
    az ad group member list --group "$GROUP" --query "[].displayName" -o tsv 2>/dev/null || echo "  (empty or not found)"
done
```

### 9.2 Verify Custom Roles

```bash
echo "=== Custom Roles ==="
az role definition list \
  --custom-role-only true \
  --query "[].{Name:roleName, Description:description}" \
  -o table
```

### 9.3 Verify Role Assignments

```bash
echo "=== Resource Group Assignments ==="
az role assignment list \
  --resource-group $RESOURCE_GROUP \
  --query "[].{Principal:principalName, Role:roleDefinitionName, Type:principalType}" \
  -o table

echo ""
echo "=== Subscription-Level Assignments ==="
az role assignment list \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --query "[?principalType!='ServicePrincipal'].{Principal:principalName, Role:roleDefinitionName}" \
  -o table
```

### 9.4 Verify Managed Identity Access

```bash
echo "=== Managed Identity ==="
az webapp identity show \
  --resource-group $RESOURCE_GROUP \
  --name $MI_APP_NAME \
  --query "{PrincipalId:principalId, TenantId:tenantId, Type:type}" \
  -o table

echo ""
echo "=== Key Vault Role Assignments ==="
az role assignment list \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KV_NAME" \
  --query "[].{Principal:principalName, Role:roleDefinitionName}" \
  -o table
```

### 9.5 Test RBAC Enforcement

```bash
# Test that Security Operator cannot modify RBAC (should fail)
# Login as the security operator:
# az login -u "lab-secops@$AD_DOMAIN" -p "<password>"
# az role assignment create --assignee <someone> --role "Owner" --scope <scope>
# Expected: Authorization error

echo "RBAC enforcement testing requires signing in as each test user."
echo "Use a private/incognito browser window to test Azure Portal access."
echo ""
echo "Test scenarios:"
echo "  1. lab-secops: Can view WAF policies, cannot modify RBAC"
echo "  2. lab-devops: Can deploy apps, cannot modify networking"
echo "  3. lab-reader: Can view resources, cannot modify anything"
```

---

## Step 10 — Cleanup

> ⚠️ **Important:** Delete all lab resources and test users when done.

```bash
# Delete resource group (includes Key Vault, App Service, Managed Identity)
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Delete test users
az ad user delete --id "lab-secops@$AD_DOMAIN" 2>/dev/null
az ad user delete --id "lab-devops@$AD_DOMAIN" 2>/dev/null
az ad user delete --id "lab-reader@$AD_DOMAIN" 2>/dev/null

# Delete security groups
az ad group delete --group "SG-Azure-Admins" 2>/dev/null
az ad group delete --group "SG-Security-Operators" 2>/dev/null
az ad group delete --group "SG-DevOps-Team" 2>/dev/null
az ad group delete --group "SG-Readers" 2>/dev/null

# Delete custom role definitions
az role definition delete --name "Security Operator" 2>/dev/null
az role definition delete --name "DevOps Deployer" 2>/dev/null

# Delete service principal
az ad sp delete --id $(az ad sp list --display-name "sp-cicd-pipeline" --query "[0].id" -o tsv) 2>/dev/null

echo "Cleanup complete. Verify in Azure Portal that all resources are deleted."
```

---

## 🆓 Free-Tier Alternatives

| Step | Premium Feature | Free Alternative | Notes |
|------|----------------|-----------------|-------|
| 4 | Conditional Access (P2) | **Security Defaults** | Baseline MFA for all admins |
| 4 | Named locations | **NSG / App Service IP restrictions** | Network-level geo-blocking |
| 5 | Azure AD MFA (P1) | **Per-user MFA (Free)** | Available in all Azure AD tiers |
| 5 | Number matching | **Standard Authenticator prompts** | Available in free tier |
| 6 | PIM (P2) | **Manual JIT scripts** | Grant/revoke access with CLI scripts |
| 6 | PIM Access Reviews | **Monthly review script** | Automated RBAC audit report |
| 8 | Sign-in Logs (P1) | **Activity Logs (Free)** | Limited to Azure resource operations |
| 8 | Risky sign-ins (P2) | **Activity Log alerts** | Alert on RBAC changes and key events |
| All | Azure AD Premium P2 trial | **30-day free trial** | Activate trial to practice PIM and CA |

### Activating Azure AD Premium P2 Trial

1. Navigate to **Microsoft Entra ID** → **Licenses** → **All products**
2. Click **+ Try/Buy**
3. Activate **Microsoft Entra ID P2** free trial (30 days)
4. This enables Conditional Access, PIM, and Risky Sign-in detection

---

## 🏆 Skills Demonstrated

### AZ-500 Exam Objectives Covered

| Domain | Skills |
|--------|--------|
| **Manage Identity & Access** | Azure AD users/groups, RBAC, custom roles, MFA, Conditional Access, PIM |
| **Platform Protection** | Managed Identities, Service Principal hardening, Key Vault RBAC |
| **Secure Data & Applications** | Key Vault integration, credential-free access, secret management |
| **Security Operations** | Audit logging, RBAC change alerts, sign-in monitoring |

### Enterprise Security Patterns Applied

- ✅ **Zero Trust** — Verify explicitly, least privilege, assume breach
- ✅ **Group-Based Access** — No individual user assignments
- ✅ **Least Privilege** — Custom roles with minimal permissions + NotActions
- ✅ **Just-in-Time Access** — PIM or manual JIT for privileged roles
- ✅ **Credential-Free Auth** — Managed Identities for services, OIDC for CI/CD
- ✅ **MFA Everywhere** — All admin access requires MFA
- ✅ **Continuous Monitoring** — Audit logs, alerts on RBAC changes
- ✅ **Access Reviews** — Regular review of role assignments

---

*Previous: [← Front Door + WAF](../Project-02-FrontDoor-WAF/README.md) | Back to [Portfolio Overview](../README.md)*
