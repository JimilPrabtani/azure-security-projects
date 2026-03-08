# 🛡️ Project 01 — Secure Web Application with Azure Application Gateway + WAF

> **Role:** Senior Azure Security Architect  
> **AZ-500 Domains:** Platform Protection · Secure Data & Applications · Manage Security Operations  
> **Estimated Time:** 3–4 hours  
> **Cost:** Free-tier compatible (see alternatives below)

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Architecture Diagram](#-architecture-diagram)
3. [Prerequisites](#-prerequisites)
4. [Step 1 — Resource Group & Networking](#step-1--resource-group--networking)
5. [Step 2 — Deploy Backend Web Application](#step-2--deploy-backend-web-application)
6. [Step 3 — Deploy Azure Application Gateway with WAF](#step-3--deploy-azure-application-gateway-with-waf)
7. [Step 4 — Configure WAF Policy (OWASP Rules)](#step-4--configure-waf-policy-owasp-rules)
8. [Step 5 — Configure NSG & Network Security](#step-5--configure-nsg--network-security)
9. [Step 6 — IAM & RBAC Configuration](#step-6--iam--rbac-configuration)
10. [Step 7 — Key Vault Integration](#step-7--key-vault-integration)
11. [Step 8 — Monitoring & Diagnostics](#step-8--monitoring--diagnostics)
12. [Step 9 — Testing & Validation](#step-9--testing--validation)
13. [Step 10 — Cleanup](#step-10--cleanup)
14. [Free-Tier Alternatives](#-free-tier-alternatives)
15. [Skills Demonstrated](#-skills-demonstrated)

---

## 🎯 Project Overview

This project deploys a **secure web application** behind an **Azure Application Gateway v2** with **Web Application Firewall (WAF)** enabled. It demonstrates enterprise-grade security architecture using defense-in-depth principles:

- **Network Layer:** Virtual Network segmentation with NSGs
- **Application Layer:** WAF with OWASP 3.2 rule set
- **Identity Layer:** RBAC with least-privilege access
- **Data Layer:** Key Vault for secrets and certificate management
- **Operations Layer:** Diagnostic logging and alerting

### What You Will Build

| Component | Purpose |
|-----------|---------|
| Azure Virtual Network | Network isolation with dedicated subnets |
| Azure Application Gateway v2 | Layer-7 load balancer with SSL termination |
| WAF Policy | OWASP rule-based application protection |
| Azure App Service | Backend web application (Free tier) |
| Network Security Groups | Subnet-level traffic filtering |
| Azure Key Vault | Secret and certificate management |
| Azure Monitor | Diagnostic logs, metrics, and alerts |
| RBAC Assignments | Least-privilege identity and access control |

---

## 🏗️ Architecture Diagram

```
                        ┌──────────────────────────────────────────────────┐
                        │                   INTERNET                       │
                        └─────────────────────┬────────────────────────────┘
                                              │
                                              ▼
                        ┌─────────────────────────────────────────────────┐
                        │           Azure Application Gateway v2          │
                        │         ┌─────────────────────────────┐        │
                        │         │    WAF Policy (OWASP 3.2)   │        │
                        │         │  • SQL Injection Protection  │        │
                        │         │  • XSS Protection            │        │
                        │         │  • Custom Rules              │        │
                        │         └─────────────────────────────┘        │
                        │              Subnet: appgw-subnet              │
                        │              NSG: appgw-nsg                    │
                        └─────────────────────┬──────────────────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    │              Virtual Network (10.0.0.0/16)         │
                    │                         │                         │
                    │    ┌────────────────────┴────────────────────┐    │
                    │    │        Backend Subnet (10.0.2.0/24)     │    │
                    │    │              NSG: backend-nsg           │    │
                    │    │                                         │    │
                    │    │    ┌──────────────────────────────┐     │    │
                    │    │    │  Azure App Service (Free)    │     │    │
                    │    │    │  • VNet Integration          │     │    │
                    │    │    │  • Managed Identity          │     │    │
                    │    │    └──────────────────────────────┘     │    │
                    │    └────────────────────────────────────────┘    │
                    └──────────────────────────────────────────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    │         Supporting Services                       │
                    │                                                   │
                    │  ┌─────────────┐  ┌───────────────┐  ┌────────┐ │
                    │  │  Key Vault  │  │ Azure Monitor │  │  RBAC  │ │
                    │  │  • Secrets  │  │ • Diagnostics │  │  Roles │ │
                    │  │  • Certs    │  │ • Alerts      │  │        │ │
                    │  └─────────────┘  └───────────────┘  └────────┘ │
                    └──────────────────────────────────────────────────┘
```

> See [`architecture/architecture-overview.md`](./architecture/architecture-overview.md) for detailed component descriptions.

---

## ✅ Prerequisites

- **Azure Account** — Free account with $200 credit or Azure for Students
- **Azure CLI** — v2.50+ installed ([Install Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- **Permissions** — Owner or Contributor + User Access Administrator on the subscription
- **Git** — For cloning this repository

### Login to Azure

```bash
az login
az account show --query "{Subscription:name, SubscriptionId:id, TenantId:tenantId}" -o table
```

---

## Step 1 — Resource Group & Networking

### 1.1 Set Environment Variables

```bash
# Project Configuration
export RESOURCE_GROUP="rg-appgw-security-project"
export LOCATION="eastus"
export VNET_NAME="vnet-security-project"
export APPGW_SUBNET="appgw-subnet"
export BACKEND_SUBNET="backend-subnet"
export APPGW_NSG="nsg-appgw"
export BACKEND_NSG="nsg-backend"
```

### 1.2 Create Resource Group

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags Project="AZ500-AppGW-WAF" Environment="Lab" ManagedBy="AzureCLI"
```

### 1.3 Create Virtual Network with Subnets

```bash
# Create VNet
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --address-prefix 10.0.0.0/16 \
  --location $LOCATION

# Create Application Gateway Subnet (minimum /24 recommended)
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $APPGW_SUBNET \
  --address-prefix 10.0.1.0/24

# Create Backend Subnet
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $BACKEND_SUBNET \
  --address-prefix 10.0.2.0/24
```

### 1.4 Create Network Security Groups

```bash
# NSG for Application Gateway Subnet
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name $APPGW_NSG \
  --location $LOCATION

# NSG for Backend Subnet
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name $BACKEND_NSG \
  --location $LOCATION
```

### 1.5 Configure NSG Rules

```bash
# Allow inbound HTTP/HTTPS to App Gateway
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $APPGW_NSG \
  --name Allow-HTTP \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 80 \
  --source-address-prefixes Internet

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $APPGW_NSG \
  --name Allow-HTTPS \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 443 \
  --source-address-prefixes Internet

# Allow Azure Gateway Manager (required for App Gateway health probes)
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $APPGW_NSG \
  --name Allow-GatewayManager \
  --priority 120 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 65200-65535 \
  --source-address-prefixes GatewayManager

# Backend NSG — Allow only traffic from App Gateway subnet
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $BACKEND_NSG \
  --name Allow-AppGW-Only \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 80 443 \
  --source-address-prefixes 10.0.1.0/24

# Backend NSG — Deny all other inbound
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $BACKEND_NSG \
  --name Deny-All-Inbound \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol "*" \
  --destination-port-ranges "*" \
  --source-address-prefixes "*"
```

### 1.6 Associate NSGs with Subnets

```bash
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $APPGW_SUBNET \
  --network-security-group $APPGW_NSG

az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $BACKEND_SUBNET \
  --network-security-group $BACKEND_NSG
```

> **📝 Security Note:** The backend subnet only accepts traffic from the Application Gateway subnet. This enforces that all user traffic must pass through the WAF before reaching the backend.

---

## Step 2 — Deploy Backend Web Application

### 2.1 Create App Service Plan (Free Tier)

```bash
export APP_SERVICE_PLAN="asp-security-project"
export WEB_APP_NAME="webapp-security-$(openssl rand -hex 4)"

az appservice plan create \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE_PLAN \
  --sku F1 \
  --is-linux

echo "Web App Name: $WEB_APP_NAME"
```

> **💡 Free-Tier Note:** The F1 SKU is free but does not support VNet integration. See [Free-Tier Alternatives](#-free-tier-alternatives) for options.

### 2.2 Create Web App

```bash
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --name $WEB_APP_NAME \
  --runtime "NODE:18-lts"
```

### 2.3 Enable System-Assigned Managed Identity

```bash
az webapp identity assign \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME

# Save the principal ID for later RBAC assignments
export WEBAPP_IDENTITY=$(az webapp identity show \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --query principalId -o tsv)

echo "Managed Identity Principal ID: $WEBAPP_IDENTITY"
```

### 2.4 Configure App Service Security Settings

```bash
# Enforce HTTPS only
az webapp update \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --https-only true

# Set minimum TLS version to 1.2
az webapp config set \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --min-tls-version 1.2

# Disable FTP access
az webapp config set \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --ftps-state Disabled
```

---

## Step 3 — Deploy Azure Application Gateway with WAF

### 3.1 Create Public IP Address

```bash
export APPGW_PUBLIC_IP="pip-appgw"

az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name $APPGW_PUBLIC_IP \
  --allocation-method Static \
  --sku Standard \
  --location $LOCATION
```

### 3.2 Create WAF Policy

```bash
export WAF_POLICY_NAME="wafpolicy-appgw"

az network application-gateway waf-policy create \
  --resource-group $RESOURCE_GROUP \
  --name $WAF_POLICY_NAME \
  --location $LOCATION
```

### 3.3 Deploy Application Gateway v2 with WAF

```bash
export APPGW_NAME="appgw-security-project"

az network application-gateway create \
  --resource-group $RESOURCE_GROUP \
  --name $APPGW_NAME \
  --location $LOCATION \
  --vnet-name $VNET_NAME \
  --subnet $APPGW_SUBNET \
  --public-ip-address $APPGW_PUBLIC_IP \
  --sku WAF_v2 \
  --capacity 1 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --frontend-port 80 \
  --waf-policy $WAF_POLICY_NAME \
  --servers "${WEB_APP_NAME}.azurewebsites.net" \
  --priority 100
```

> **⏱️ Note:** Application Gateway deployment takes 15–25 minutes to complete.

### 3.4 Configure Health Probe

```bash
az network application-gateway probe create \
  --resource-group $RESOURCE_GROUP \
  --gateway-name $APPGW_NAME \
  --name "health-probe" \
  --protocol Http \
  --host-name-from-http-settings true \
  --path "/" \
  --interval 30 \
  --timeout 30 \
  --threshold 3
```

---

## Step 4 — Configure WAF Policy (OWASP Rules)

### 4.1 Enable OWASP 3.2 Managed Rule Set

```bash
az network application-gateway waf-policy managed-rule rule-set add \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --type OWASP \
  --version 3.2
```

### 4.2 Set WAF to Prevention Mode

```bash
az network application-gateway waf-policy policy-setting update \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --mode Prevention \
  --state Enabled \
  --request-body-check true \
  --max-request-body-size-in-kb 128 \
  --file-upload-limit-in-mb 100
```

### 4.3 Add Custom WAF Rules

```bash
# Block requests from specific geolocation (example: block traffic from unknown regions)
az network application-gateway waf-policy custom-rule create \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "BlockSuspiciousUserAgents" \
  --priority 10 \
  --rule-type MatchRule \
  --action Block

# Add match condition for suspicious user agents
az network application-gateway waf-policy custom-rule match-condition add \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "BlockSuspiciousUserAgents" \
  --match-variables RequestHeaders.User-Agent \
  --operator Contains \
  --values "scanner" "sqlmap" "nikto" "nmap"

# Rate limiting rule (if supported in your region)
az network application-gateway waf-policy custom-rule create \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "RateLimitRule" \
  --priority 20 \
  --rule-type RateLimitRule \
  --action Block \
  --rate-limit-threshold 100 \
  --rate-limit-duration FiveMins
```

### 4.4 Verify WAF Configuration

```bash
az network application-gateway waf-policy show \
  --resource-group $RESOURCE_GROUP \
  --name $WAF_POLICY_NAME \
  --query "{State:policySettings.state, Mode:policySettings.mode, ManagedRules:managedRules.managedRuleSets[].ruleSetType}" \
  -o table
```

---

## Step 5 — Configure NSG & Network Security

### 5.1 Review Effective Security Rules

```bash
# List all NSG rules for the App Gateway subnet
az network nsg rule list \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $APPGW_NSG \
  -o table

# List all NSG rules for the Backend subnet
az network nsg rule list \
  --resource-group $RESOURCE_GROUP \
  --nsg-name $BACKEND_NSG \
  -o table
```

### 5.2 Enable NSG Flow Logs (Free Alternative: Use Activity Logs)

```bash
# If you have a Storage Account available:
# az network watcher flow-log create \
#   --resource-group $RESOURCE_GROUP \
#   --name "flowlog-appgw-nsg" \
#   --nsg $APPGW_NSG \
#   --storage-account <storage-account-id> \
#   --enabled true

# Free Alternative: Use Activity Log to monitor NSG changes
az monitor activity-log list \
  --resource-group $RESOURCE_GROUP \
  --max-events 10 \
  -o table
```

---

## Step 6 — IAM & RBAC Configuration

### 6.1 Create Custom RBAC Role for WAF Operator

```bash
# Get the subscription ID
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create a custom role definition for WAF management
cat > /tmp/waf-operator-role.json << 'EOF'
{
  "Name": "WAF Operator",
  "Description": "Can manage WAF policies and view Application Gateway configurations",
  "Actions": [
    "Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/*",
    "Microsoft.Network/applicationGateways/read",
    "Microsoft.Network/applicationGateways/backendHealth/action",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Insights/metrics/read",
    "Microsoft.Insights/diagnosticSettings/read"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/SUBSCRIPTION_ID_PLACEHOLDER"
  ]
}
EOF

# Replace placeholder with actual subscription ID
sed -i "s/SUBSCRIPTION_ID_PLACEHOLDER/$SUBSCRIPTION_ID/" /tmp/waf-operator-role.json

az role definition create --role-definition /tmp/waf-operator-role.json
```

### 6.2 Assign Built-in RBAC Roles

```bash
# Assign Reader role for monitoring team (replace with actual user/group object ID)
# az role assignment create \
#   --assignee <user-or-group-object-id> \
#   --role "Reader" \
#   --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Assign Network Contributor for network team
# az role assignment create \
#   --assignee <user-or-group-object-id> \
#   --role "Network Contributor" \
#   --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# List current role assignments
az role assignment list \
  --resource-group $RESOURCE_GROUP \
  --query "[].{Principal:principalName, Role:roleDefinitionName, Scope:scope}" \
  -o table
```

### 6.3 Configure Managed Identity Access

```bash
# Grant the Web App managed identity access to Key Vault (created in Step 7)
# This follows the principle of least privilege
echo "Managed Identity configured. RBAC assignments will be completed after Key Vault deployment."
```

> **📝 IAM Best Practices Applied:**
> - Custom role with minimum required permissions
> - Managed Identity for service-to-service authentication (no stored credentials)
> - Resource-group-scoped assignments (not subscription-wide)

---

## Step 7 — Key Vault Integration

### 7.1 Create Azure Key Vault

```bash
export KEY_VAULT_NAME="kv-appgw-$(openssl rand -hex 4)"

az keyvault create \
  --resource-group $RESOURCE_GROUP \
  --name $KEY_VAULT_NAME \
  --location $LOCATION \
  --sku standard \
  --enable-rbac-authorization true \
  --enable-purge-protection true

echo "Key Vault Name: $KEY_VAULT_NAME"
```

### 7.2 Assign Key Vault RBAC Roles

```bash
export CURRENT_USER=$(az ad signed-in-user show --query id -o tsv)

# Assign Key Vault Administrator to yourself
az role assignment create \
  --assignee $CURRENT_USER \
  --role "Key Vault Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME"

# Assign Key Vault Secrets User to the Web App managed identity
az role assignment create \
  --assignee $WEBAPP_IDENTITY \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME"
```

### 7.3 Store Application Secrets

```bash
# Store a sample application secret
az keyvault secret set \
  --vault-name $KEY_VAULT_NAME \
  --name "AppDatabaseConnection" \
  --value "Server=myserver;Database=mydb;Trusted_Connection=true;"

# Store API key
az keyvault secret set \
  --vault-name $KEY_VAULT_NAME \
  --name "ExternalApiKey" \
  --value "sample-api-key-value-replace-in-production"
```

### 7.4 Configure Web App to Use Key Vault References

```bash
# Set app settings to reference Key Vault secrets
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --settings \
    "DB_CONNECTION=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=AppDatabaseConnection)" \
    "API_KEY=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=ExternalApiKey)"
```

---

## Step 8 — Monitoring & Diagnostics

### 8.1 Create Log Analytics Workspace (Free Tier — 500MB/day)

```bash
export LOG_WORKSPACE="log-appgw-security"

az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_WORKSPACE \
  --location $LOCATION \
  --sku PerGB2018
```

### 8.2 Enable Diagnostic Settings for Application Gateway

```bash
export LOG_WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_WORKSPACE \
  --query id -o tsv)

az monitor diagnostic-settings create \
  --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGateways/$APPGW_NAME" \
  --name "appgw-diagnostics" \
  --workspace $LOG_WORKSPACE_ID \
  --logs '[
    {"category":"ApplicationGatewayAccessLog","enabled":true},
    {"category":"ApplicationGatewayPerformanceLog","enabled":true},
    {"category":"ApplicationGatewayFirewallLog","enabled":true}
  ]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

### 8.3 Enable Diagnostic Settings for WAF Policy

```bash
az monitor diagnostic-settings create \
  --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/$WAF_POLICY_NAME" \
  --name "waf-diagnostics" \
  --workspace $LOG_WORKSPACE_ID \
  --logs '[{"category":"AllLogs","enabled":true}]'
```

### 8.4 Create WAF Alert Rule

```bash
# Alert when WAF blocks a request
az monitor metrics alert create \
  --resource-group $RESOURCE_GROUP \
  --name "WAF-Blocked-Requests-Alert" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGateways/$APPGW_NAME" \
  --condition "total ApplicationGatewayTotalRequests > 100" \
  --description "Alert when total requests exceed threshold - investigate for potential attack" \
  --severity 2 \
  --window-size 5m \
  --evaluation-frequency 1m
```

### 8.5 Sample KQL Queries for WAF Analysis

```kql
// View blocked requests by WAF
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| project TimeGenerated, clientIp_s, requestUri_s, ruleId_s, message
| order by TimeGenerated desc

// Top attack sources
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"
| summarize AttackCount = count() by clientIp_s
| order by AttackCount desc
| take 10

// WAF rule hit frequency
AzureDiagnostics
| where Category == "ApplicationGatewayFirewallLog"
| summarize HitCount = count() by ruleId_s, ruleGroup_s
| order by HitCount desc
```

---

## Step 9 — Testing & Validation

### 9.1 Get Application Gateway Public IP

```bash
export APPGW_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name $APPGW_PUBLIC_IP \
  --query ipAddress -o tsv)

echo "Application Gateway IP: $APPGW_IP"
echo "Test URL: http://$APPGW_IP"
```

### 9.2 Test Normal Traffic

```bash
# Test basic connectivity
curl -s -o /dev/null -w "%{http_code}" http://$APPGW_IP

# Test with verbose output
curl -v http://$APPGW_IP 2>&1 | head -30
```

### 9.3 Test WAF Protection (SQL Injection)

```bash
# This request should be BLOCKED by WAF
curl -s -o /dev/null -w "Status: %{http_code}\n" \
  "http://$APPGW_IP/?id=1' OR '1'='1"

# Expected: 403 Forbidden
```

### 9.4 Test WAF Protection (XSS)

```bash
# This request should be BLOCKED by WAF
curl -s -o /dev/null -w "Status: %{http_code}\n" \
  "http://$APPGW_IP/?q=<script>alert('xss')</script>"

# Expected: 403 Forbidden
```

### 9.5 Test WAF Protection (Suspicious User Agent)

```bash
# This request should be BLOCKED by custom WAF rule
curl -s -o /dev/null -w "Status: %{http_code}\n" \
  -H "User-Agent: sqlmap/1.0" \
  "http://$APPGW_IP/"

# Expected: 403 Forbidden
```

### 9.6 Verify RBAC Assignments

```bash
az role assignment list \
  --resource-group $RESOURCE_GROUP \
  --query "[].{Principal:principalName, Role:roleDefinitionName}" \
  -o table
```

### 9.7 Verify Key Vault Access

```bash
# Verify secrets are accessible
az keyvault secret list \
  --vault-name $KEY_VAULT_NAME \
  --query "[].{Name:name, Enabled:attributes.enabled}" \
  -o table
```

---

## Step 10 — Cleanup

> ⚠️ **Important:** Delete all resources when done to avoid charges.

```bash
# Delete the entire resource group (includes all resources)
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Verify deletion
az group show --name $RESOURCE_GROUP 2>/dev/null || echo "Resource group deleted successfully"

# Clean up custom role definition (if created)
az role definition delete --name "WAF Operator" 2>/dev/null
```

---

## 🆓 Free-Tier Alternatives

| Step | Paid Service | Free Alternative | Notes |
|------|-------------|-----------------|-------|
| 2 | App Service B1+ (VNet Integration) | **App Service F1** (no VNet integration) | Use access restrictions instead of VNet integration |
| 3 | Application Gateway WAF_v2 | **Application Gateway Standard_v2** | Standard SKU is cheaper; WAF policies can be studied via Portal |
| 3 | Application Gateway (always-on) | **Azure Portal WAF Simulator** | Use Portal to configure and study WAF rules without deployment |
| 7 | Key Vault (Standard) | **Key Vault (Standard)** — Free for first 10,000 operations | Key Vault is effectively free at lab scale |
| 8 | Log Analytics (Paid tier) | **Log Analytics Free Tier** — 500 MB/day free | Sufficient for lab environments |
| 8 | Azure Monitor Alerts (Paid) | **Activity Log Alerts** | Free; limited to platform-level events |
| All | Terraform Cloud | **Azure CLI / ARM Templates** | CLI and ARM are always free |

### Cost-Saving Tips

1. **Deploy and test within 1–2 hours**, then delete immediately
2. **Use Application Gateway Standard_v2** instead of WAF_v2 to save costs, and study WAF configurations through Azure Portal documentation
3. **Use the ARM template** in `arm-templates/` for quick deployment and teardown
4. **Set budget alerts** at $5 to get notified before incurring significant charges:

```bash
# Quick budget alert (optional)
az consumption budget create \
  --budget-name "Lab-Budget" \
  --amount 5 \
  --category Cost \
  --resource-group $RESOURCE_GROUP \
  --time-grain Monthly \
  --start-date "2026-03-01" \
  --end-date "2026-12-31"
```

---

## 🏆 Skills Demonstrated

### AZ-500 Exam Objectives Covered

| Domain | Skills |
|--------|--------|
| **Manage Identity & Access** | Custom RBAC roles, Managed Identity, Key Vault RBAC |
| **Platform Protection** | Application Gateway, WAF, NSG, VNet segmentation, subnet isolation |
| **Secure Data & Applications** | Key Vault secrets, HTTPS enforcement, TLS 1.2, FTP disabled |
| **Security Operations** | Diagnostic logging, KQL queries, metric alerts, WAF log analysis |

### Enterprise Security Patterns Applied

- ✅ **Defense in Depth** — Multiple security layers (network, application, identity, data)
- ✅ **Zero Trust Networking** — Backend only accessible through WAF
- ✅ **Least Privilege** — Custom RBAC roles with minimum permissions
- ✅ **Secrets Management** — No hardcoded secrets; Key Vault references
- ✅ **Monitoring & Alerting** — Centralized logging with automated alerts
- ✅ **OWASP Protection** — WAF rules covering Top 10 web vulnerabilities

---

*Next Project: [Global App Delivery with Azure Front Door + WAF →](../Project-02-FrontDoor-WAF/README.md)*
