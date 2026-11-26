# Identity & Access Governance Architecture Runbook

## 1. Executive Summary & Threat Model
Legacy enterprise environments frequently accumulate standing privileged directory assignments across individual administrator accounts and shared operational identities. This baseline addresses four primary identity attack vectors:
- **Credential Compromise & Standing Privilege:** Permanent high-privilege directory roles (`Global Administrator`, `Privileged Role Administrator`, `Security Administrator`) create an unrestricted blast radius if a single daily-driver account is phished.
- **Lack of Non-Repudiation (Shared Operational IDs):** Shared administrative accounts obscure individual accountability in Entra ID Directory Audit Logs and complicate MFA enforcement.
- **Tenant Lockout Risk:** Misconfigured Conditional Access policies or identity provider disruptions can lock out all administrators if cloud-only emergency access accounts are absent.
- **Unmonitored Privilege Drift:** Without automated role inventory, standing assignments and broad `TenantWide` (`/`) scopes persist unnoticed.

---

## 2. Emergency Access (Break-Glass) Architecture
To guarantee administrative recovery during MFA outages, federation failures, or Conditional Access misconfigurations, two cloud-only emergency access accounts are provisioned:
- **Identity Type:** Cloud-native (`*.onmicrosoft.com`), decoupled from on-premises Active Directory sync and external federation.
- **Policy Exclusions:** Explicitly excluded from all Conditional Access policies (`CA001`–`CA005`) and never converted to PIM-eligible assignments, ensuring zero dependency on PIM activation services during an outage.
- **Credential Custody:** Protected with phishing-resistant FIDO2 security keys or split-custody high-entropy passphrases stored offline.
- **Detection Over Prevention:** Because preventive Conditional Access blocks are bypassed, `SigninLogs` are routed to Azure Monitor / Log Analytics with high-severity alerts triggered on any sign-in attempt.

---

## 3. Privileged Identity Management (PIM) Target Policy Design
In environments licensed for Entra ID P2 / Governance, standing administrative access transitions to Just-In-Time (JIT) elevation:
- **Standing vs. Eligible Separation:** Human administrators hold **Eligible** assignments rather than permanent **Active** assignments.
- **Activation Controls:**
  - **Authentication:** Phishing-resistant MFA required at activation (`authentication_strength_policy_id`).
  - **Maximum Duration:** Capped at **4 hours** per activation window (`sign_in_frequency = 4`, `persistent_browser_mode = "never"`).
  - **Auditability:** Mandatory ticket/incident justification required prior to activation.
- **Phased Rollout for Legacy Environments:** Where immediate PIM enforcement conflicts with legacy automation or operational workflows, roll out in three non-disruptive phases:
  1. **Phase 1 (Read-Only Visibility):** Inventory standing roles via Microsoft Graph PowerShell (`audit-entra-role-assignments.ps1`) and deploy Conditional Access in Report-Only mode (`enabledForReportingButNotEnforced`).
  2. **Phase 2 (Shared ID Retirement & Admin Separation):** Replace shared admin IDs with dedicated `-adm` accounts and migrate background jobs to Managed Identities or Certificate-based App Registrations.
  3. **Phase 3 (JIT Enforcement):** Convert standing human role holders to PIM-eligible assignments once MFA registration and non-interactive service migrations are verified.

---

## 4. Automated Privilege Auditing (`audit-entra-role-assignments.ps1`)
To eliminate manual portal reviews, a read-only Microsoft Graph PowerShell script audits directory role posture across the tenant:
- **Scope:** Queries `Get-MgRoleManagementDirectoryRoleAssignment` (standing/active roles) and `Get-MgRoleManagementDirectoryRoleEligibilitySchedule` (PIM eligible schedules).
- **Principal Resolution:** Resolves `User`, `Group`, and `ServicePrincipal` objects via `Get-MgDirectoryObject` to catch non-human principals holding directory roles.
- **Blast-Radius Classification:** Flags `TenantWide` (`/`) assignments separately from `Scoped` Administrative Unit assignments.
- **Sanitized Output Hygiene:** Exports findings locally to CSV (excluded via `.gitignore`) for offline review without committing tenant PII to source control.
