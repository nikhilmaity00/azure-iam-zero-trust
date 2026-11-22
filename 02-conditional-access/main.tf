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