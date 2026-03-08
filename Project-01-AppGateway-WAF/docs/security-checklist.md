# Security Checklist — Application Gateway + WAF Project

Use this checklist to verify all security controls are properly configured.

## Network Security

- [ ] Virtual Network created with proper address space
- [ ] Dedicated subnet for Application Gateway (minimum /24)
- [ ] Separate subnet for backend services
- [ ] NSG on Application Gateway subnet allows only HTTP/HTTPS and Gateway Manager
- [ ] NSG on backend subnet allows only traffic from Application Gateway subnet
- [ ] Deny-all rule in place for backend subnet
- [ ] No public IP directly assigned to backend resources

## Application Security (WAF)

- [ ] WAF Policy created and associated with Application Gateway
- [ ] OWASP 3.2 managed rule set enabled
- [ ] WAF mode set to Prevention (not just Detection)
- [ ] Request body inspection enabled
- [ ] Custom rule to block known attack tools (sqlmap, nikto, nmap)
- [ ] Rate limiting rule configured (if supported)
- [ ] SQL Injection attacks blocked (verified with test)
- [ ] XSS attacks blocked (verified with test)
- [ ] Path traversal attacks blocked (verified with test)

## Identity & Access Management

- [ ] Custom RBAC role created with least-privilege permissions
- [ ] Managed Identity enabled on App Service
- [ ] No stored credentials in application code or settings
- [ ] Key Vault RBAC authorization enabled (not access policies)
- [ ] Key Vault Secrets User role assigned to App Managed Identity
- [ ] RBAC assignments scoped to resource group (not subscription)

## Data Protection

- [ ] HTTPS-only enabled on App Service
- [ ] Minimum TLS version set to 1.2
- [ ] FTP access disabled on App Service
- [ ] Secrets stored in Key Vault (not in app settings)
- [ ] Key Vault references configured for app settings
- [ ] Key Vault purge protection enabled

## Monitoring & Operations

- [ ] Log Analytics workspace created
- [ ] Diagnostic settings enabled for Application Gateway
- [ ] Access logs being collected
- [ ] Firewall logs being collected
- [ ] Performance logs being collected
- [ ] Alert rule configured for suspicious activity
- [ ] KQL queries prepared for WAF log analysis

## Cleanup

- [ ] Resource group deletion command documented
- [ ] Custom role cleanup command documented
- [ ] Budget alert configured (optional)
