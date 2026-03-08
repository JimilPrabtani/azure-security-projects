# 🛡️ Azure Security Projects — AZ-500 Hands-On Portfolio

> **Role:** Senior Azure Security Architect (Practice)  
> **Certification Target:** AZ-500 — Microsoft Azure Security Technologies  
> **Author:** Jimil Prabtani  
> **Last Updated:** March 2026

---

## 📁 Repository Structure

```
azure-security-projects/
├── Project-01-AppGateway-WAF/
│   ├── README.md                  # Step-by-step guide (10 steps)
│   ├── architecture/
│   │   └── architecture-overview.md
│   ├── arm-templates/
│   │   ├── deploy-appgw.json      # Full ARM template
│   │   └── deploy-appgw.parameters.json
│   ├── scripts/
│   │   ├── deploy.sh              # One-click deployment
│   │   ├── cleanup.sh             # Resource cleanup
│   │   └── test-waf.sh            # WAF test suite
│   └── docs/
│       └── security-checklist.md
├── Project-02-FrontDoor-WAF/
│   ├── README.md                  # Step-by-step guide (9 steps)
│   ├── architecture/
│   │   └── architecture-overview.md
│   ├── arm-templates/
│   │   ├── deploy-frontdoor.json  # Full ARM template
│   │   └── deploy-frontdoor.parameters.json
│   ├── scripts/
│   │   ├── deploy.sh              # One-click deployment
│   │   ├── cleanup.sh             # Resource cleanup
│   │   └── test-waf.sh            # WAF test suite
│   └── docs/
│       └── security-checklist.md
├── Project-03-IAM-RBAC-Security/
│   ├── README.md                  # Step-by-step guide (10 steps)
│   ├── scripts/
│   │   └── cleanup.sh             # Full cleanup script
│   └── docs/
│       ├── security-checklist.md
│       └── rbac-roles-reference.md
└── README.md  ← (this file)
```

---

## 🚀 Projects Overview

| # | Project | Azure Services | Security Domains |
|---|---------|---------------|-----------------|
| 01 | [Secure Web App with Azure Application Gateway + WAF](./Project-01-AppGateway-WAF/README.md) | App Gateway v2, WAF Policy, App Service, NSG, Key Vault, Log Analytics | WAF (OWASP 3.2), Custom RBAC, Network Segmentation, Secrets Management |
| 02 | [Global App Delivery with Azure Front Door + WAF](./Project-02-FrontDoor-WAF/README.md) | Front Door Standard, WAF Policy (DRS 2.1), Multi-Region App Service | Edge WAF, Geo-Filtering, Rate Limiting, Backend Lockdown |
| 03 | [IAM & RBAC Hardening](./Project-03-IAM-RBAC-Security/README.md) | Azure AD/Entra ID, Custom RBAC Roles, Managed Identities, Key Vault, PIM | Zero Trust, Least Privilege, MFA, Conditional Access, JIT Access |

---

## 🎯 AZ-500 Domains Covered

| AZ-500 Domain | Projects | Key Skills |
|---------------|----------|------------|
| **Manage Identity and Access** | 01, 02, 03 | Azure AD users/groups, custom RBAC roles, managed identities, MFA, Conditional Access, PIM |
| **Implement Platform Protection** | 01, 02 | Application Gateway WAF, Front Door WAF, NSG rules, VNet segmentation, geo-filtering |
| **Secure Data and Applications** | 01, 02, 03 | Key Vault RBAC, secrets management, HTTPS enforcement, TLS 1.2, credential-free auth |
| **Manage Security Operations** | 01, 02, 03 | Log Analytics, diagnostic settings, KQL queries, metric alerts, RBAC change monitoring |

---

## 🏁 Quick Start

### Option 1: Step-by-Step (Recommended for Learning)
Follow each project's README.md which provides CLI commands for every step.

### Option 2: ARM Template Deployment
```bash
# Project 01 — Application Gateway + WAF
cd Project-01-AppGateway-WAF/scripts && chmod +x deploy.sh && ./deploy.sh

# Project 02 — Front Door + WAF
cd Project-02-FrontDoor-WAF/scripts && chmod +x deploy.sh && ./deploy.sh
```

### Prerequisites
- Azure Free Account or Azure for Students ($200 credit)
- Azure CLI v2.50+ ([Install Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- Owner or Contributor role on your subscription

---

## 🆓 Free-Tier Friendly

All projects are designed to work within the **Azure Free Account** or **Azure for Students** credit limits. Each project documents:
- ✅ Which services are free
- ✅ Which services consume credits (with estimated costs)
- ✅ Free alternatives for every paid feature
- ✅ Cost-saving tips and budget alerts

---

## 🏆 Enterprise Security Patterns Demonstrated

- **Defense in Depth** — Multiple security layers (network → application → identity → data)
- **Zero Trust** — Verify explicitly, least privilege, assume breach
- **OWASP Protection** — WAF rules covering Top 10 web vulnerabilities
- **Separation of Duties** — Custom RBAC roles for distinct job functions
- **Credential-Free Authentication** — Managed Identities and OIDC federation
- **Centralized Monitoring** — Log Analytics with KQL queries and automated alerts

---

*This portfolio demonstrates real-world Azure security architecture skills aligned with enterprise standards and AZ-500 certification objectives.*
