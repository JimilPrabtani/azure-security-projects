# Architecture Overview — Secure Web App with Application Gateway + WAF

## Component Descriptions

### Azure Virtual Network (VNet)

- **Address Space:** 10.0.0.0/16
- **Purpose:** Provides network isolation for all project resources
- **Subnets:**
  - `appgw-subnet` (10.0.1.0/24) — Dedicated to Application Gateway (required)
  - `backend-subnet` (10.0.2.0/24) — Hosts backend services

### Azure Application Gateway v2

- **SKU:** WAF_v2 (or Standard_v2 for free-tier alternative)
- **Purpose:** Layer-7 load balancer providing SSL termination, URL-based routing, and WAF capabilities
- **Key Features Used:**
  - Web Application Firewall
  - Health probes for backend monitoring
  - HTTP-to-HTTPS redirection
  - Backend pool targeting App Service

### WAF Policy

- **Rule Set:** OWASP 3.2
- **Mode:** Prevention (blocks malicious requests)
- **Custom Rules:**
  - Block suspicious user agents (scanners, attack tools)
  - Rate limiting to prevent DDoS at the application layer

### Network Security Groups (NSGs)

| NSG | Subnet | Purpose |
|-----|--------|---------|
| `nsg-appgw` | appgw-subnet | Allow HTTP/HTTPS from Internet + Gateway Manager ports |
| `nsg-backend` | backend-subnet | Allow only traffic from App Gateway subnet; deny all other inbound |

### Azure App Service (Free Tier)

- **SKU:** F1 (Free)
- **Runtime:** Node.js 18 LTS
- **Security Hardening:**
  - HTTPS-only enabled
  - Minimum TLS 1.2
  - FTP disabled
  - System-assigned Managed Identity enabled

### Azure Key Vault

- **SKU:** Standard
- **Authorization:** RBAC-based (not access policies)
- **Purge Protection:** Enabled
- **Contents:**
  - Application connection strings
  - API keys
  - (Optional) SSL certificates for Application Gateway

### Azure Monitor / Log Analytics

- **Workspace SKU:** PerGB2018 (500 MB/day free)
- **Diagnostic Logs Collected:**
  - Application Gateway Access Log
  - Application Gateway Performance Log
  - Application Gateway Firewall Log
- **Alerts:** Metric-based alerts for request thresholds

## Data Flow

```
User Request → Internet → Public IP → Application Gateway (WAF Inspection)
  ├── If blocked by WAF → 403 response returned
  └── If allowed → Backend Pool → App Service → Response to User
```

## Security Controls Summary

| Layer | Control | Implementation |
|-------|---------|---------------|
| Network | Segmentation | VNet with dedicated subnets |
| Network | Traffic filtering | NSGs with least-privilege rules |
| Application | WAF | OWASP 3.2 in Prevention mode |
| Application | Custom rules | Block scanners, rate limiting |
| Identity | RBAC | Custom roles, managed identity |
| Identity | Secrets | Key Vault with RBAC authorization |
| Data | Encryption in transit | HTTPS-only, TLS 1.2 minimum |
| Operations | Logging | Centralized Log Analytics workspace |
| Operations | Alerting | Metric-based alerts on WAF activity |
