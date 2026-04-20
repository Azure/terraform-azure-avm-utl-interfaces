mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

variables {
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  this_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.KeyVault/vaults/kv-test"
}

run "no_diagnostic_settings" {
  command = apply

  assert {
    error_message = "Diagnostic settings output should be empty when no input provided."
    condition     = length(output.diagnostic_settings_azapi) == 0
  }
}

run "diagnostic_settings_with_log_groups_deprecated" {
  command = apply

  variables {
    diagnostic_settings = {
      test = {
        name = "diag-test"
        log_groups = ["allLogs"]
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
  }

  assert {
    error_message = "Should have one diagnostic setting."
    condition     = length(output.diagnostic_settings_azapi) == 1
  }

  assert {
    error_message = "Diagnostic setting name should match."
    condition     = output.diagnostic_settings_azapi["test"].name == "diag-test"
  }

  assert {
    error_message = "Body should contain workspace ID."
    condition     = output.diagnostic_settings_azapi["test"].body.properties.workspaceId == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
  }
}

run "diagnostic_settings_with_new_logs" {
  command = apply

  variables {
    diagnostic_settings = {
      test = {
        name = "diag-new-logs"
        logs = [
          {
            category_group = "allLogs"
            enabled        = true
          }
        ]
        metrics = [
          {
            category = "AllMetrics"
            enabled  = true
          }
        ]
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/law"
      }
    }
  }

  assert {
    error_message = "Should have one diagnostic setting."
    condition     = length(output.diagnostic_settings_azapi) == 1
  }

  assert {
    error_message = "Logs should contain allLogs category group."
    condition     = output.diagnostic_settings_azapi["test"].body.properties.logs[0].categoryGroup == "allLogs"
  }

  assert {
    error_message = "Metrics should contain AllMetrics category."
    condition     = output.diagnostic_settings_azapi["test"].body.properties.metrics[0].category == "AllMetrics"
  }

  assert {
    error_message = "Logs should include retention policy."
    condition     = output.diagnostic_settings_azapi["test"].body.properties.logs[0].retentionPolicy.enabled == false
  }
}
