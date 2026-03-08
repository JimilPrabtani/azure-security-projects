# 🌐 Project 02 — Global Application Delivery with Azure Front Door + WAF

> **Role:** Senior Azure Security Architect  
> **AZ-500 Domains:** Platform Protection · Secure Data & Applications · Manage Security Operations  
> **Estimated Time:** 2–3 hours  
> **Cost:** Free-tier compatible (see alternatives below)

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Architecture Diagram](#-architecture-diagram)
3. [Prerequisites](#-prerequisites)
4. [Step 1 — Resource Group & Backend Setup](#step-1--resource-group--backend-setup)
5. [Step 2 — Deploy Azure Front Door Standard](#step-2--deploy-azure-front-door-standard)
6. [Step 3 — Configure WAF Policy for Front Door](#step-3--configure-waf-policy-for-front-door)
7. [Step 4 — Custom WAF Rules & Rate Limiting](#step-4--custom-waf-rules--rate-limiting)
8. [Step 5 — IAM & RBAC Configuration](#step-5--iam--rbac-configuration)
9. [Step 6 — Geo-Filtering & Access Restrictions](#step-6--geo-filtering--access-restrictions)
10. [Step 7 — Monitoring & Diagnostics](#step-7--monitoring--diagnostics)
11. [Step 8 — Testing & Validation](#step-8--testing--validation)
12. [Step 9 — Cleanup](#step-9--cleanup)
13. [Free-Tier Alternatives](#-free-tier-alternatives)
14. [Skills Demonstrated](#-skills-demonstrated)

---

## 🎯 Project Overview

This project deploys a **globally distributed web application** using **Azure Front Door Standard** with **WAF policies** to protect against web attacks, implement geo-filtering, and demonstrate rate limiting. It showcases enterprise-grade global application delivery with security at the edge.

### What You Will Build

| Component | Purpose |
|-----------|---------|
| Azure Front Door Standard | Global CDN + reverse proxy with edge security |
| Front Door WAF Policy | OWASP DRS 2.1 rule-based application protection |
| Custom WAF Rules | Geo-filtering, rate limiting, IP restrictions |
| Azure App Service (2 regions) | Multi-region backend web applications |
| Azure Monitor | WAF diagnostics, access logs, and alerting |
| RBAC Assignments | Least-privilege access for Front Door management |

### Key Differences: Front Door vs. Application Gateway

| Feature | Azure Front Door | Azure Application Gateway |
|---------|-----------------|--------------------------|
| **Scope** | Global (edge PoPs worldwide) | Regional (single VNet) |
| **Layer** | Layer 7 (global) | Layer 7 (regional) |
| **Use Case** | Multi-region apps, CDN, global WAF | Single-region apps, VNet-integrated WAF |
| **WAF Rule Sets** | DRS (Default Rule Set) | OWASP CRS |
| **Geo-Filtering** | Built-in | Not available |
| **SSL Termination** | At edge PoPs worldwide | At regional gateway |

---

## 🏗️ Architecture Diagram

```
                    ┌──────────────────────────────────────────┐
                    │              GLOBAL USERS                │
                    │    🇺🇸 US    🇪🇺 Europe    🇮🇳 Asia       │
                    └──────────────┬───────────────────────────┘
                                   │
                                   ▼
            ┌──────────────────────────────────────────────────┐
            │           Azure Front Door Standard              │
            │  ┌────────────────────────────────────────────┐  │
            │  │          WAF Policy (DRS 2.1)              │  │
            │  │  • OWASP Top 10 Protection                │  │
            │  │  • Geo-Filtering Rules                    │  │
            │  │  • Rate Limiting (100 req/min)            │  │
            │  │  • Custom IP Blocklist                    │  │
            │  │  • Bot Protection                         │  │
            │  └────────────────────────────────────────────┘  │
            │                                                  │
            │  Endpoint: myapp.azurefd.net                     │
            │  Custom Domain: (optional)                       │
            └──────────────┬──────────────┬────────────────────┘
                           │              │
              ┌────────────┘              └────────────┐
              ▼                                        ▼
    ┌──────────────────────┐              ┌──────────────────────┐
    │  Origin Group 1      │              │  Origin Group 2      │
    │  (Primary - East US) │              │  (Secondary - West)  │
    │                      │              │                      │
    │  ┌────────────────┐  │              │  ┌────────────────┐  │
    │  │  App Service   │  │              │  │  App Service   │  │
    │  │  (Free Tier)   │  │              │  │  (Free Tier)   │  │
    │  │  East US       │  │              │  │  West US       │  │
    │  └────────────────┘  │              │  └────────────────┘  │
    └──────────────────────┘              └──────────────────────┘
                           │              │
              ┌────────────┘              └────────────┐
              ▼                                        ▼
    ┌──────────────────────────────────────────────────────────┐
    │                  Supporting Services                     │
    │                                                          │
    │  ┌──────────────┐  ┌───────────────┐  ┌──────────────┐  │
    │  │ Log Analytics │  │ Azure Monitor │  │   RBAC       │  │
    │  │ • WAF Logs   │  │ • Alerts      │  │   Controls   │  │
    │  │ • Access Logs│  │ • Metrics     │  │              │  │
    │  └──────────────┘  └───────────────┘  └──────────────┘  │
    └──────────────────────────────────────────────────────────┘
```

> See [`architecture/architecture-overview.md`](./architecture/architecture-overview.md) for detailed component descriptions.

---

## ✅ Prerequisites

- **Azure Account** — Free account with $200 credit or Azure for Students
- **Azure CLI** — v2.50+ installed ([Install Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- **Permissions** — Owner or Contributor + User Access Administrator on the subscription

### Login to Azure

```bash
az login
az account show --query "{Subscription:name, SubscriptionId:id, TenantId:tenantId}" -o table
```

---

## Step 1 — Resource Group & Backend Setup

### 1.1 Set Environment Variables

```bash
# Project Configuration
export RESOURCE_GROUP="rg-frontdoor-security-project"
export LOCATION_PRIMARY="eastus"
export LOCATION_SECONDARY="westus"
export APP_SERVICE_PLAN_PRIMARY="asp-fd-primary"
export APP_SERVICE_PLAN_SECONDARY="asp-fd-secondary"
export WEB_APP_PRIMARY="webapp-fd-primary-$(openssl rand -hex 4)"
export WEB_APP_SECONDARY="webapp-fd-secondary-$(openssl rand -hex 4)"
```

### 1.2 Create Resource Group

```bash
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION_PRIMARY \
  --tags Project="AZ500-FrontDoor-WAF" Environment="Lab" ManagedBy="AzureCLI"
```

### 1.3 Deploy Primary Backend (East US)

```bash
# Create App Service Plan (Free tier)
az appservice plan create \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE_PLAN_PRIMARY \
  --location $LOCATION_PRIMARY \
  --sku F1 \
  --is-linux

# Create Web App
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN_PRIMARY \
  --name $WEB_APP_PRIMARY \
  --runtime "NODE:18-lts"

# Security hardening
az webapp update --resource-group $RESOURCE_GROUP --name $WEB_APP_PRIMARY --https-only true
az webapp config set --resource-group $RESOURCE_GROUP --name $WEB_APP_PRIMARY --min-tls-version 1.2 --ftps-state Disabled

echo "Primary App: https://$WEB_APP_PRIMARY.azurewebsites.net"
```

### 1.4 Deploy Secondary Backend (West US)

```bash
# Create App Service Plan (Free tier)
az appservice plan create \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE_PLAN_SECONDARY \
  --location $LOCATION_SECONDARY \
  --sku F1 \
  --is-linux

# Create Web App
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN_SECONDARY \
  --name $WEB_APP_SECONDARY \
  --runtime "NODE:18-lts"

# Security hardening
az webapp update --resource-group $RESOURCE_GROUP --name $WEB_APP_SECONDARY --https-only true
az webapp config set --resource-group $RESOURCE_GROUP --name $WEB_APP_SECONDARY --min-tls-version 1.2 --ftps-state Disabled

echo "Secondary App: https://$WEB_APP_SECONDARY.azurewebsites.net"
```

### 1.5 Enable Managed Identity on Both Apps

```bash
az webapp identity assign --resource-group $RESOURCE_GROUP --name $WEB_APP_PRIMARY
az webapp identity assign --resource-group $RESOURCE_GROUP --name $WEB_APP_SECONDARY
```

> **📝 Note:** Two backend apps in different regions demonstrate Front Door's global load balancing and failover capabilities.

---

## Step 2 — Deploy Azure Front Door Standard

### 2.1 Create Front Door Profile

```bash
export FRONT_DOOR_NAME="fd-security-project-$(openssl rand -hex 4)"

az afd profile create \
  --resource-group $RESOURCE_GROUP \
  --profile-name $FRONT_DOOR_NAME \
  --sku Standard_AzureFrontDoor

echo "Front Door Profile: $FRONT_DOOR_NAME"
```

### 2.2 Create Front Door Endpoint

```bash
export FD_ENDPOINT="endpoint-security"

az afd endpoint create \
  --resource-group $RESOURCE_GROUP \
  --profile-name $FRONT_DOOR_NAME \
  --endpoint-name $FD_ENDPOINT \
  --enabled-state Enabled
```

### 2.3 Create Origin Group

```bash
az afd origin-group create \
  --resource-group $RESOURCE_GROUP \
  --profile-name $FRONT_DOOR_NAME \
  --origin-group-name "backend-origins" \
  --probe-request-type GET \
  --probe-protocol Https \
  --probe-interval-in-seconds 30 \
  --probe-path "/" \
  --sample-size 4 \
  --successful-samples-required 3 \
  --additional-latency-in-milliseconds 50
```

### 2.4 Add Origins (Backend Apps)

```bash
# Primary origin (East US)
az afd origin create \
  --resource-group $RESOURCE_GROUP \
  --profile-name $FRONT_DOOR_NAME \
  --origin-group-name "backend-origins" \
  --origin-name "primary-origin" \
  --host-name "${WEB_APP_PRIMARY}.azurewebsites.net" \
  --origin-host-header "${WEB_APP_PRIMARY}.azurewebsites.net" \
  --http-port 80 \
  --https-port 443 \
  --priority 1 \
  --weight 1000 \
  --enabled-state Enabled

# Secondary origin (West US) — Lower priority for failover
az afd origin create \
  --resource-group $RESOURCE_GROUP \
  --profile-name $FRONT_DOOR_NAME \
  --origin-group-name "backend-origins" \
  --origin-name "secondary-origin" \
  --host-name "${WEB_APP_SECONDARY}.azurewebsites.net" \
  --origin-host-header "${WEB_APP_SECONDARY}.azurewebsites.net" \
  --http-port 80 \
  --https-port 443 \
  --priority 2 \
  --weight 1000 \
  --enabled-state Enabled
```

### 2.5 Create Route

```bash
az afd route create \
  --resource-group $RESOURCE_GROUP \
  --profile-name $FRONT_DOOR_NAME \
  --endpoint-name $FD_ENDPOINT \
  --route-name "default-route" \
  --origin-group "backend-origins" \
  --supported-protocols Https Http \
  --patterns-to-match "/*" \
  --forwarding-protocol HttpsOnly \
  --https-redirect Enabled \
  --link-to-default-domain Enabled
```

### 2.6 Get Front Door Endpoint URL

```bash
export FD_HOSTNAME=$(az afd endpoint show \
  --resource-group $RESOURCE_GROUP \
  --profile-name $FRONT_DOOR_NAME \
  --endpoint-name $FD_ENDPOINT \
  --query hostName -o tsv)

echo "Front Door URL: https://$FD_HOSTNAME"
```

---

## Step 3 — Configure WAF Policy for Front Door

### 3.1 Create WAF Policy

```bash
export WAF_POLICY_NAME="wafpolicyfd"

az network front-door waf-policy create \
  --resource-group $RESOURCE_GROUP \
  --name $WAF_POLICY_NAME \
  --sku Standard_AzureFrontDoor \
  --disabled false \
  --mode Prevention
```

### 3.2 Enable Default Rule Set (DRS 2.1)

```bash
az network front-door waf-policy managed-rules add \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --type DefaultRuleSet \
  --version 2.1
```

### 3.3 Enable Bot Manager Rule Set

```bash
# Note: Bot Manager may require Premium SKU. For Standard, use custom rules instead.
# az network front-door waf-policy managed-rules add \
#   --resource-group $RESOURCE_GROUP \
#   --policy-name $WAF_POLICY_NAME \
#   --type Microsoft_BotManagerRuleSet \
#   --version 1.0

echo "Bot Manager requires Premium SKU. Using custom rules for bot protection instead."
```

### 3.4 Associate WAF Policy with Front Door

```bash
# Get the WAF policy resource ID
export WAF_POLICY_ID=$(az network front-door waf-policy show \
  --resource-group $RESOURCE_GROUP \
  --name $WAF_POLICY_NAME \
  --query id -o tsv)

# Create security policy to associate WAF with Front Door endpoint
az afd security-policy create \
  --resource-group $RESOURCE_GROUP \
  --profile-name $FRONT_DOOR_NAME \
  --security-policy-name "waf-security-policy" \
  --domains "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Cdn/profiles/$FRONT_DOOR_NAME/afdEndpoints/$FD_ENDPOINT" \
  --waf-policy $WAF_POLICY_ID
```

---

## Step 4 — Custom WAF Rules & Rate Limiting

### 4.1 Rate Limiting Rule

```bash
az network front-door waf-policy rule create \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "RateLimitRule" \
  --priority 10 \
  --rule-type RateLimitRule \
  --action Block \
  --rate-limit-threshold 100 \
  --rate-limit-duration-in-minutes 1

az network front-door waf-policy rule match-condition add \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "RateLimitRule" \
  --match-variable RequestUri \
  --operator Contains \
  --values "/"
```

### 4.2 Block Suspicious User Agents

```bash
az network front-door waf-policy rule create \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "BlockScanners" \
  --priority 20 \
  --rule-type MatchRule \
  --action Block

az network front-door waf-policy rule match-condition add \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "BlockScanners" \
  --match-variable RequestHeader \
  --selector "User-Agent" \
  --operator Contains \
  --values "scanner" "sqlmap" "nikto" "nmap" "masscan"
```

### 4.3 IP Blocklist Rule

```bash
az network front-door waf-policy rule create \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "IPBlocklist" \
  --priority 30 \
  --rule-type MatchRule \
  --action Block

# Add known malicious IP ranges (example — replace with actual IPs)
az network front-door waf-policy rule match-condition add \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "IPBlocklist" \
  --match-variable RemoteAddr \
  --operator IPMatch \
  --values "192.0.2.0/24" "198.51.100.0/24"
```

### 4.4 Verify WAF Configuration

```bash
az network front-door waf-policy show \
  --resource-group $RESOURCE_GROUP \
  --name $WAF_POLICY_NAME \
  --query "{Mode:policySettings.mode, State:policySettings.enabledState, ManagedRules:managedRules.managedRuleSets[].ruleSetType, CustomRules:customRules[].name}" \
  -o json
```

---

## Step 5 — IAM & RBAC Configuration

### 5.1 Create Custom RBAC Role for Front Door Operator

```bash
export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

cat > /tmp/fd-operator-role.json << 'EOF'
{
  "Name": "Front Door Security Operator",
  "Description": "Can manage Front Door WAF policies, endpoints, and view configurations",
  "Actions": [
    "Microsoft.Cdn/profiles/read",
    "Microsoft.Cdn/profiles/endpoints/read",
    "Microsoft.Cdn/profiles/securityPolicies/*",
    "Microsoft.Network/frontDoorWebApplicationFirewallPolicies/*",
    "Microsoft.Resources/subscriptions/resourceGroups/read",
    "Microsoft.Insights/metrics/read",
    "Microsoft.Insights/diagnosticSettings/read",
    "Microsoft.Insights/logDefinitions/read"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/SUBSCRIPTION_ID_PLACEHOLDER"
  ]
}
EOF

sed -i "s/SUBSCRIPTION_ID_PLACEHOLDER/$SUBSCRIPTION_ID/" /tmp/fd-operator-role.json

az role definition create --role-definition /tmp/fd-operator-role.json
```

### 5.2 Review Existing RBAC Assignments

```bash
# List all role assignments in the resource group
az role assignment list \
  --resource-group $RESOURCE_GROUP \
  --query "[].{Principal:principalName, Role:roleDefinitionName, Scope:scope}" \
  -o table
```

### 5.3 Recommended Role Assignments

```bash
# Security Team — Can manage WAF policies but not Front Door routing
# az role assignment create \
#   --assignee <security-team-group-id> \
#   --role "Front Door Security Operator" \
#   --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# Operations Team — Read-only access for monitoring
# az role assignment create \
#   --assignee <ops-team-group-id> \
#   --role "Reader" \
#   --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"

# CDN Endpoint Contributor — Built-in role for Front Door management
# az role assignment create \
#   --assignee <cdn-admin-id> \
#   --role "CDN Endpoint Contributor" \
#   --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
```

> **📝 IAM Best Practices Applied:**
> - Separation of duties: Security team manages WAF, operations team has read-only
> - Custom role with minimum required permissions for Front Door WAF management
> - All assignments scoped to resource group, not subscription

---

## Step 6 — Geo-Filtering & Access Restrictions

### 6.1 Geo-Filtering WAF Rule (Block Specific Countries)

```bash
az network front-door waf-policy rule create \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "GeoFilterRule" \
  --priority 40 \
  --rule-type MatchRule \
  --action Block

# Block traffic from specific countries (ISO 3166-1 alpha-2 codes)
# Example: Block traffic not from US, CA, GB, IN, DE
az network front-door waf-policy rule match-condition add \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --name "GeoFilterRule" \
  --match-variable RemoteAddr \
  --operator GeoMatch \
  --negate \
  --values "US" "CA" "GB" "IN" "DE"
```

### 6.2 Restrict Backend Access to Front Door Only

```bash
# Get the Front Door ID header value
export FD_ID=$(az afd profile show \
  --resource-group $RESOURCE_GROUP \
  --profile-name $FRONT_DOOR_NAME \
  --query frontDoorId -o tsv)

echo "Front Door ID: $FD_ID"

# Configure App Service access restriction — allow only Front Door
az webapp config access-restriction add \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_PRIMARY \
  --rule-name "AllowFrontDoorOnly" \
  --action Allow \
  --priority 100 \
  --service-tag AzureFrontDoor.Backend \
  --http-header "X-Azure-FDID=$FD_ID"

az webapp config access-restriction add \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_SECONDARY \
  --rule-name "AllowFrontDoorOnly" \
  --action Allow \
  --priority 100 \
  --service-tag AzureFrontDoor.Backend \
  --http-header "X-Azure-FDID=$FD_ID"
```

> **🔒 Security Note:** This ensures that users cannot bypass Front Door (and its WAF) by accessing the App Service URLs directly.

---

## Step 7 — Monitoring & Diagnostics

### 7.1 Create Log Analytics Workspace

```bash
export LOG_WORKSPACE="log-frontdoor-security"

az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_WORKSPACE \
  --location $LOCATION_PRIMARY \
  --sku PerGB2018
```

### 7.2 Enable Front Door Diagnostic Logs

```bash
export LOG_WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_WORKSPACE \
  --query id -o tsv)

export FD_RESOURCE_ID=$(az afd profile show \
  --resource-group $RESOURCE_GROUP \
  --profile-name $FRONT_DOOR_NAME \
  --query id -o tsv)

az monitor diagnostic-settings create \
  --resource "$FD_RESOURCE_ID" \
  --name "fd-diagnostics" \
  --workspace $LOG_WORKSPACE_ID \
  --logs '[
    {"category":"FrontDoorAccessLog","enabled":true},
    {"category":"FrontDoorWebApplicationFirewallLog","enabled":true},
    {"category":"FrontDoorHealthProbeLog","enabled":true}
  ]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

### 7.3 Create Alert for WAF Blocked Requests

```bash
az monitor metrics alert create \
  --resource-group $RESOURCE_GROUP \
  --name "FD-WAF-Blocked-Alert" \
  --scopes "$FD_RESOURCE_ID" \
  --condition "total WebApplicationFirewallRequestCount > 50" \
  --description "Alert when WAF blocks exceed threshold" \
  --severity 2 \
  --window-size 5m \
  --evaluation-frequency 1m
```

### 7.4 Sample KQL Queries for Front Door WAF

```kql
// All WAF blocked requests
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.CDN"
| where Category == "FrontDoorWebApplicationFirewallLog"
| where action_s == "Block"
| project TimeGenerated, clientIP_s, requestUri_s, ruleName_s, policy_s
| order by TimeGenerated desc

// Top blocked IPs
AzureDiagnostics
| where Category == "FrontDoorWebApplicationFirewallLog"
| where action_s == "Block"
| summarize BlockCount = count() by clientIP_s
| order by BlockCount desc
| take 10

// Request distribution by country
AzureDiagnostics
| where Category == "FrontDoorAccessLog"
| summarize RequestCount = count() by clientCountry_s
| order by RequestCount desc

// Origin health status
AzureDiagnostics
| where Category == "FrontDoorHealthProbeLog"
| project TimeGenerated, originName_s, healthProbeResult_s
| order by TimeGenerated desc
| take 20

// Latency analysis by origin
AzureDiagnostics
| where Category == "FrontDoorAccessLog"
| summarize AvgLatency = avg(timeTaken_d) by originName_s, bin(TimeGenerated, 5m)
| render timechart
```

---

## Step 8 — Testing & Validation

### 8.1 Test Basic Connectivity

```bash
echo "Front Door URL: https://$FD_HOSTNAME"

# Test basic connectivity
curl -s -o /dev/null -w "Status: %{http_code}\n" "https://$FD_HOSTNAME"

# Verify HTTPS redirect
curl -s -o /dev/null -w "Redirect Status: %{http_code}\n" "http://$FD_HOSTNAME" -L
```

### 8.2 Test WAF SQL Injection Protection

```bash
# This should be BLOCKED (403)
curl -s -o /dev/null -w "SQL Injection: %{http_code}\n" \
  "https://$FD_HOSTNAME/?id=1' OR '1'='1"

curl -s -o /dev/null -w "UNION SELECT: %{http_code}\n" \
  "https://$FD_HOSTNAME/?id=1 UNION SELECT * FROM users"
```

### 8.3 Test WAF XSS Protection

```bash
# This should be BLOCKED (403)
curl -s -o /dev/null -w "XSS Attack: %{http_code}\n" \
  "https://$FD_HOSTNAME/?q=<script>alert('xss')</script>"
```

### 8.4 Test Custom Rules

```bash
# Test scanner user agent block
curl -s -o /dev/null -w "Scanner Block: %{http_code}\n" \
  -H "User-Agent: sqlmap/1.0" \
  "https://$FD_HOSTNAME/"

# Test nikto user agent block
curl -s -o /dev/null -w "Nikto Block: %{http_code}\n" \
  -H "User-Agent: nikto/2.1.6" \
  "https://$FD_HOSTNAME/"
```

### 8.5 Test Backend Access Restriction

```bash
# Direct access to backend should be denied (403)
curl -s -o /dev/null -w "Direct Primary: %{http_code}\n" \
  "https://$WEB_APP_PRIMARY.azurewebsites.net"

curl -s -o /dev/null -w "Direct Secondary: %{http_code}\n" \
  "https://$WEB_APP_SECONDARY.azurewebsites.net"

# Access through Front Door should work (200)
curl -s -o /dev/null -w "Via Front Door: %{http_code}\n" \
  "https://$FD_HOSTNAME"
```

### 8.6 Verify RBAC Assignments

```bash
az role assignment list \
  --resource-group $RESOURCE_GROUP \
  --query "[].{Principal:principalName, Role:roleDefinitionName}" \
  -o table
```

---

## Step 9 — Cleanup

> ⚠️ **Important:** Delete all resources when done to avoid charges.

```bash
# Delete the entire resource group
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Verify deletion
az group show --name $RESOURCE_GROUP 2>/dev/null || echo "Resource group deleted successfully"

# Clean up custom role definition
az role definition delete --name "Front Door Security Operator" 2>/dev/null
```

---

## 🆓 Free-Tier Alternatives

| Step | Paid Service | Free Alternative | Notes |
|------|-------------|-----------------|-------|
| 1 | App Service B1+ | **App Service F1** (Free) | Free tier sufficient for Front Door backends |
| 2 | Front Door Premium | **Front Door Standard** | Standard includes WAF; Premium adds Bot Manager, Private Link |
| 2 | Front Door (always-on) | **Azure Portal exploration** | Study configurations via Portal without deploying |
| 3 | WAF Premium rules | **WAF Standard rules (DRS 2.1)** | Standard DRS covers OWASP Top 10 |
| 3 | Bot Manager (Premium) | **Custom WAF rules** | Manually block known bot user agents |
| 7 | Log Analytics (Paid) | **Log Analytics Free Tier** (500 MB/day) | Sufficient for lab environments |
| 7 | Azure Monitor Alerts | **Activity Log Alerts** | Free; limited to platform events |
| — | Multi-region deployment | **Single-region with 1 backend** | Reduces cost; still demonstrates Front Door concepts |

### Cost-Saving Tips

1. **Deploy, test, and delete within 1–2 hours** to minimize Front Door charges
2. **Use a single backend** instead of two if budget is tight
3. **Standard SKU** is significantly cheaper than Premium
4. **Set a budget alert** at $5:

```bash
az consumption budget create \
  --budget-name "Lab-Budget-FD" \
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
| **Manage Identity & Access** | Custom RBAC roles, Managed Identity, separation of duties |
| **Platform Protection** | Front Door WAF, geo-filtering, rate limiting, access restrictions |
| **Secure Data & Applications** | HTTPS enforcement, TLS 1.2, backend lockdown |
| **Security Operations** | Diagnostic logging, KQL queries, metric alerts, health monitoring |

### Enterprise Security Patterns Applied

- ✅ **Global Edge Protection** — WAF enforcement at 180+ edge locations worldwide
- ✅ **Defense in Depth** — WAF at edge + access restrictions on backend
- ✅ **Geo-Filtering** — Block traffic from unauthorized regions
- ✅ **Rate Limiting** — Prevent application-layer DDoS attacks
- ✅ **Backend Lockdown** — Backend only accessible through Front Door
- ✅ **Separation of Duties** — Security team and operations team with distinct roles
- ✅ **Monitoring** — Centralized WAF logging with automated alerting
- ✅ **Multi-Region Resilience** — Automatic failover between regions

---

*Previous: [← Application Gateway + WAF](../Project-01-AppGateway-WAF/README.md) | Next: [IAM & RBAC Hardening →](../Project-03-IAM-RBAC-Security/README.md)*
