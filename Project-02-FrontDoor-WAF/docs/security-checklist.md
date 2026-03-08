# Security Checklist — Front Door + WAF Project

Use this checklist to verify all security controls are properly configured.

## Front Door Configuration

- [ ] Front Door Standard profile created
- [ ] Endpoint created and enabled
- [ ] Origin group with health probes configured
- [ ] Primary origin added (East US)
- [ ] Secondary origin added (West US) with lower priority
- [ ] Default route configured with HTTPS redirect
- [ ] HTTPS-only forwarding to backends

## WAF Policy

- [ ] WAF policy created and associated with Front Door endpoint
- [ ] Default Rule Set (DRS) 2.1 enabled
- [ ] WAF mode set to Prevention (not just Detection)
- [ ] Request body inspection enabled
- [ ] Rate limiting custom rule configured (100 req/min)
- [ ] Scanner blocking custom rule configured
- [ ] IP blocklist custom rule configured
- [ ] SQL Injection attacks blocked (verified with test)
- [ ] XSS attacks blocked (verified with test)
- [ ] Path traversal attacks blocked (verified with test)

## Geo-Filtering

- [ ] Geo-filtering WAF rule configured
- [ ] Allowed countries defined
- [ ] Rule tested and verified

## Backend Security

- [ ] Both App Services enforce HTTPS-only
- [ ] Minimum TLS version set to 1.2
- [ ] FTP access disabled
- [ ] Managed Identity enabled on both App Services
- [ ] Access restriction configured — allow only AzureFrontDoor.Backend service tag
- [ ] X-Azure-FDID header validation configured
- [ ] Direct access to backend URLs returns 403

## Identity & Access Management

- [ ] Custom RBAC role created for Front Door Security Operator
- [ ] Custom role has least-privilege permissions
- [ ] RBAC assignments scoped to resource group
- [ ] Separation of duties between security and operations teams

## Monitoring & Operations

- [ ] Log Analytics workspace created
- [ ] Diagnostic settings enabled for Front Door profile
- [ ] Access logs being collected
- [ ] WAF logs being collected
- [ ] Health probe logs being collected
- [ ] Alert rule configured for WAF blocked requests
- [ ] KQL queries prepared for WAF analysis

## Cleanup

- [ ] Resource group deletion command documented
- [ ] Custom role cleanup command documented
- [ ] Budget alert configured (optional)
