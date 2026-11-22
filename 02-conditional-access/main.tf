resource "azuread_conditional_access_policy" "ca002_block_legacy_auth" {
  display_name = "CA002 - Block Legacy Authentication"
  state        = "enabledForReportingButNotEnforced" # Always deploy in Report-Only first!

  conditions {
    client_app_types    = ["exchangeActiveSync", "other"]
    sign_in_risk_levels = []
    user_risk_levels    = []

    applications {
      included_applications = ["All"]
    }

    users {
      included_users = ["All"]
      excluded_users = [var.break_glass_object_id]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}

resource "azuread_conditional_access_policy" "ca004_require_compliant_device" {
  display_name = "CA004 - Require Compliant Device"
  state        = "enabledForReportingButNotEnforced" # Always deploy in Report-Only first!

  conditions {
    client_app_types    = ["browser", "mobileAppsAndDesktopClients"]
#    sign_in_risk_levels = []
#    user_risk_levels    = []

    applications {
      included_applications = ["Office365"]
    }

    users {
      included_users = ["All"]
      excluded_users = [var.break_glass_object_id,"GuestsOrExternalUsers"]
    }
    platforms {
      included_platforms = ["windows","macOS","iOS","android"]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["compliantDevice"]
  }
  
}

# CA001: Require Phishing-Resistant MFA + 4-Hour Session Timeout for Admins
resource "azuread_conditional_access_policy" "ca001_admin_phishing_resistant_mfa" {
  display_name = "CA001 - Require Phishing-Resistant MFA for Admins"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_roles = [
        "62e90394-69f5-4237-9190-012177145e10", # Global Administrator
        "194ae4cb-b126-40b2-bd5b-6091b380977d", # Security Administrator
        "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9", # Conditional Access Administrator
        "e8611ab8-c189-46e8-94e1-60213ab1f814", # Privileged Role Administrator
      ]
      excluded_users = [var.break_glass_object_id]
    }
  }

  grant_controls {
    operator                          = "OR"
    authentication_strength_policy_id = "00000000-0000-0000-0000-000000000004" # Built-in: Phishing-resistant MFA
  }

  session_controls {
    sign_in_frequency        = 4
    sign_in_frequency_period = "hours"
    persistent_browser_mode  = "never"
  }
}

# CA003: Require Standard MFA for All Users
resource "azuread_conditional_access_policy" "ca003_require_mfa_all_users" {
  display_name = "CA003 - Require MFA for All Users"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users = ["All"]
      excluded_users = [var.break_glass_object_id]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}

# CA005: Block High-Risk Sign-ins (Requires Entra ID P2)
resource "azuread_conditional_access_policy" "ca005_block_high_risk_signins" {
  display_name = "CA005 - Block High-Risk Sign-ins"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types    = ["all"]
    sign_in_risk_levels = ["high"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_users = ["All"]
      excluded_users = [var.break_glass_object_id]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["block"]
  }
}