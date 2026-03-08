# Architecture Overview — Global Application Delivery with Front Door + WAF

## Component Descriptions

### Azure Front Door Standard

- **SKU:** Standard_AzureFrontDoor
- **Purpose:** Global Layer-7 reverse proxy and CDN providing edge security, SSL termination, and intelligent routing
- **Key Features Used:**
  - WAF policy association via security policies
  - Health probes for backend monitoring
  - HTTP-to-HTTPS redirect
  - Priority-based routing for failover
  - Latency-based routing for performance

### Front Door WAF Policy

- **Rule Set:** Default Rule Set (DRS) 2.1
- **Mode:** Prevention (blocks malicious requests at the edge)
- **Custom Rules:**
  - Rate limiting: 100 requests per minute per IP
  - User agent blocking: Known attack tools (sqlmap, nikto, nmap)
  - IP blocklist: Known malicious IP ranges
  - Geo-filtering: Allow traffic only from authorized countries

### Origin Groups & Origins

| Origin | Region | Priority | Purpose |
|--------|--------|----------|---------|
| Primary (App Service) | East US | 1 | Primary backend — receives all traffic |
| Secondary (App Service) | West US | 2 | Failover backend — activated if primary is unhealthy |

**Failover Configuration:**
- Health probe interval: 30 seconds
- Sample size: 4 probes
- Successful samples required: 3
- Additional latency threshold: 50ms

### App Service Access Restrictions

Both backend App Services are configured to:
- **Allow** traffic only from the `AzureFrontDoor.Backend` service tag
- **Validate** the `X-Azure-FDID` header matches our specific Front Door instance
- **Deny** all direct access attempts

This ensures users cannot bypass Front Door's WAF by accessing backend URLs directly.

### Azure Monitor / Log Analytics

- **Workspace SKU:** PerGB2018 (500 MB/day free)
- **Diagnostic Logs Collected:**
  - Front Door Access Log — all requests
  - Front Door WAF Log — WAF actions (allow/block/log)
  - Front Door Health Probe Log — backend health status
- **Alerts:** WAF blocked request threshold

## Data Flow

```
Global User → Nearest Azure PoP → Front Door (WAF Inspection at Edge)
  ├── If blocked by WAF → 403 response at edge (low latency)
  └── If allowed → Route to healthiest origin
       ├── Primary (East US) — Priority 1
       └── Secondary (West US) — Priority 2 (failover)
            └── App Service → Response via Front Door → User
```

## Security Controls Summary

| Layer | Control | Implementation |
|-------|---------|---------------|
| Edge | WAF | DRS 2.1 in Prevention mode at all PoPs |
| Edge | Rate limiting | 100 req/min per IP |
| Edge | Geo-filtering | Allow only from authorized countries |
| Edge | Bot protection | Custom rules blocking known attack tools |
| Application | Access restriction | Backend locked to Front Door only |
| Application | Header validation | X-Azure-FDID verification |
| Data | Encryption in transit | HTTPS-only with TLS 1.2+ |
| Data | HTTPS redirect | Automatic HTTP-to-HTTPS |
| Identity | RBAC | Custom roles, managed identity |
| Operations | Logging | Centralized Log Analytics |
| Operations | Alerting | Metric-based alerts on WAF activity |

## Comparison: Front Door vs. Application Gateway

Use this section to understand when to choose each service:

| Criteria | Choose Front Door | Choose Application Gateway |
|----------|------------------|---------------------------|
| App users are globally distributed | ✅ | |
| App is deployed in a single region | | ✅ |
| Need geo-filtering | ✅ | |
| Need VNet integration | | ✅ |
| Need private backend connectivity | ✅ (Premium) | ✅ |
| Need URL-based routing within a region | | ✅ |
| Budget is limited | Standard SKU | Standard_v2 SKU |
| Need both global and regional protection | ✅ Front Door + App Gateway together | |
