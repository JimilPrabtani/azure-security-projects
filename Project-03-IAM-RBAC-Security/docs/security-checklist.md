# IAM & RBAC Security Checklist

Use this checklist to verify all identity and access controls are properly configured.

## Azure AD Configuration

- [ ] Security groups created (SG-Azure-Admins, SG-Security-Operators, SG-DevOps-Team, SG-Readers)
- [ ] Test users created with force-change-password-next-sign-in enabled
- [ ] Users assigned to appropriate security groups
- [ ] No orphaned user accounts

## RBAC Custom Roles

- [ ] Custom role "Security Operator" created with least-privilege permissions
- [ ] Custom role "DevOps Deployer" created with least-privilege permissions
- [ ] Custom roles include NotActions to explicitly deny dangerous operations
- [ ] Custom roles scoped to subscription (not management group)
- [ ] Roles assigned to groups, not individual users

## Role Assignments

- [ ] SG-Security-Operators → Security Operator (resource group scope)
- [ ] SG-DevOps-Team → DevOps Deployer (resource group scope)
- [ ] SG-Readers → Reader (subscription scope)
- [ ] No Owner role permanently assigned to regular users
- [ ] No Contributor role at subscription level for non-admin groups

## Managed Identities

- [ ] System-assigned managed identity enabled on App Service
- [ ] User-assigned managed identity created
- [ ] Managed identity granted Key Vault Secrets User role
- [ ] Key Vault uses RBAC authorization (not access policies)
- [ ] App Service uses Key Vault references for secrets
- [ ] No credentials stored in application code or settings

## Conditional Access (Premium P2 or Security Defaults)

- [ ] MFA required for all admin roles
- [ ] Legacy authentication blocked
- [ ] Security Defaults enabled (if no Premium license)
- [ ] Break-glass account excluded from all policies
- [ ] Policies tested in Report-only mode before enabling

## Multi-Factor Authentication

- [ ] MFA enabled for all admin accounts
- [ ] MFA methods configured (Authenticator, FIDO2 preferred)
- [ ] SMS-based MFA disabled or de-prioritized
- [ ] All users have registered MFA methods

## Privileged Identity Management (Premium P2 or Manual JIT)

- [ ] Privileged roles set to Eligible (not permanently Active)
- [ ] Maximum activation duration set (e.g., 4 hours)
- [ ] Justification required for activation
- [ ] Approval required for high-privilege roles (Owner)
- [ ] MFA required for activation
- [ ] Email notifications on activation

## Service Principals

- [ ] Service principal created with minimal role (DevOps Deployer)
- [ ] Service principal scoped to resource group
- [ ] Credential expiry set (1 year maximum)
- [ ] Credential rotation plan documented
- [ ] Federated credentials configured for CI/CD (preferred over secrets)

## Monitoring & Audit

- [ ] Activity log alerts configured for RBAC changes
- [ ] Activity log alerts configured for Key Vault access
- [ ] KQL queries prepared for identity monitoring
- [ ] Monthly access review process documented
- [ ] Sign-in logs reviewed (if Premium available)

## Cleanup

- [ ] Test user deletion commands documented
- [ ] Security group deletion commands documented
- [ ] Custom role deletion commands documented
- [ ] Service principal deletion commands documented
- [ ] Resource group deletion commands documented
