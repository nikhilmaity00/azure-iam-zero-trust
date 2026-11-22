# Zero Trust Conditional Access as Code (Terraform)

Baseline Microsoft Entra ID Conditional Access policies codified with the `azuread` Terraform provider, designed around least privilege, blast-radius containment, and safe rollout practices.

## Architecture & Rollout Strategy

- **Safe Rollout (`enabledForReportingButNotEnforced`):** All baseline policies start in Report-Only mode so sign-in logs and impact can be audited before enforcing access blocks or device/MFA requirements.
- **Blast-Radius Containment:** Emergency access (break-glass) accounts are explicitly excluded from Conditional Access policies so administrative recovery remains possible if policy or MFA configurations fail.
- **Tiered Risk Controls:** Privileged directory roles are separated from general user policies so strict phishing-resistant authentication strengths and shorter session lifetimes apply to high-impact identities without creating unnecessary friction across standard users.
- **Licensing Boundaries:** Risk-based sign-in conditions (`CA005`) and device compliance enforcement (`CA004`) align with Entra ID P2 and Intune capabilities respectively.

## Policy Matrix

| Policy ID | Policy Name | Included Scope | Exclusions | Target Apps | Conditions | Grant / Session Controls |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **CA001** | Require Phishing-Resistant MFA for Admins | Global Admin, Security Admin, CA Admin, Privileged Role Admin | Break-Glass account | All Cloud Apps | All client apps | Phishing-resistant authentication strength; 4-hour sign-in frequency; non-persistent browser session |
| **CA002** | Block Legacy Authentication | All Users | Break-Glass account | All Cloud Apps | Exchange ActiveSync & Other legacy client types | Block access |
| **CA003** | Require MFA for All Users | All Users | Break-Glass account | All Cloud Apps | All client apps | Require MFA |
| **CA004** | Require Compliant Device | All Users | Break-Glass account, Guests/External Users | Office 365 | Browser & mobile/desktop clients across Windows, macOS, iOS, Android | Require compliant device |
| **CA005** | Block High-Risk Sign-ins | All Users | Break-Glass account | All Cloud Apps | High sign-in risk (Entra ID P2) | Block access |

## Repository Layout

- `providers.tf` — Configures Terraform and the `hashicorp/azuread` provider.
- `variables.tf` — Declares input variables such as `break_glass_object_id`.
- `main.tf` — Defines the five `azuread_conditional_access_policy` resources.