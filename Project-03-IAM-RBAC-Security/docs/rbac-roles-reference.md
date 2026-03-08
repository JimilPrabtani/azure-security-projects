# RBAC Role Definitions Reference

This document provides reference material for all custom RBAC roles used across the Azure Security Projects portfolio.

---

## Custom Roles Created

### 1. Security Operator

**Used in:** Project 01 (App Gateway), Project 02 (Front Door), Project 03 (IAM)

```json
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
  ]
}
```

### 2. DevOps Deployer

**Used in:** Project 03 (IAM)

```json
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
  ]
}
```

### 3. WAF Operator

**Used in:** Project 01 (App Gateway)

```json
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
  "NotActions": []
}
```

### 4. Front Door Security Operator

**Used in:** Project 02 (Front Door)

```json
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
  "NotActions": []
}
```

---

## Built-in Roles Referenced

| Role | Project | Scope | Assignee |
|------|---------|-------|----------|
| Reader | All | Subscription | SG-Readers group |
| Key Vault Administrator | 01, 03 | Key Vault resource | Admin users |
| Key Vault Secrets User | 01, 03 | Key Vault resource | Managed Identities |
| Network Contributor | 01 | Resource Group | Network team |
| CDN Endpoint Contributor | 02 | Resource Group | CDN admin |

---

## RBAC Design Principles

1. **Group-Based Assignment** — Always assign roles to Azure AD security groups, never to individual users
2. **Least Privilege** — Each custom role contains only the minimum permissions needed for the job function
3. **NotActions** — Explicitly deny dangerous operations (RBAC changes, network modifications)
4. **Scoped Assignment** — Assign at the narrowest scope possible (resource > resource group > subscription)
5. **Separation of Duties** — Security, DevOps, and Operations teams have distinct, non-overlapping roles
6. **Just-in-Time** — Privileged roles should be Eligible (PIM) rather than permanently Active
