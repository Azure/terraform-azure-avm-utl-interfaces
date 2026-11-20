mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {}

variables {
  location = "uksouth"
}

run "logs_without_log_categories" {
  command = apply

  variables {
    diagnostic_settings_v2 = {
      eh = {
        event_hub_authorization_rule_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.EventHub/namespaces/ns/authorizationRules/rule"
        logs = [
          { category = "AppPageViews" },
          { category = "AppEvents" },
        ]
      }
    }
  }

  assert {
    condition     = [for log in output.diagnostic_settings_azapi_v2["eh"].body.properties.logs : log.category] == ["AppEvents", "AppPageViews"]
    error_message = "Without log_categories, the body must contain only the categories in logs."
  }
}

run "log_categories_set_the_order" {
  command = apply

  variables {
    diagnostic_settings_v2 = {
      eh = {
        event_hub_authorization_rule_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.EventHub/namespaces/ns/authorizationRules/rule"
        log_categories                           = ["AppAvailabilityResults", "AppEvents", "AppMetrics", "AppDependencies", "AppPageViews"]
        logs = [
          { category = "AppPageViews" },
          { category = "AppDependencies" },
          { category = "AppMetrics", enabled = false },
        ]
      }
    }
  }

  assert {
    condition = [for log in output.diagnostic_settings_azapi_v2["eh"].body.properties.logs : [log.category, log.enabled]] == [
      ["AppDependencies", true],
      ["AppPageViews", true],
      ["AppAvailabilityResults", false],
      ["AppEvents", false],
      ["AppMetrics", false],
    ]
    error_message = "With log_categories, the body must list the enabled categories first and then the disabled ones, each in the order of log_categories."
  }

  assert {
    condition     = alltrue([for log in output.diagnostic_settings_azapi_v2["eh"].body.properties.logs : log.categoryGroup == null && log.retentionPolicy.days == 0 && log.retentionPolicy.enabled == false])
    error_message = "Each log must have no category group and the default retention policy."
  }
}

run "log_categories_must_contain_each_category" {
  command = plan

  variables {
    diagnostic_settings_v2 = {
      eh = {
        event_hub_authorization_rule_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.EventHub/namespaces/ns/authorizationRules/rule"
        log_categories                           = ["AppEvents"]
        logs = [
          { category = "AppTraces" },
        ]
      }
    }
  }

  expect_failures = [var.diagnostic_settings_v2]
}

run "log_categories_reject_category_groups" {
  command = plan

  variables {
    diagnostic_settings_v2 = {
      eh = {
        event_hub_authorization_rule_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.EventHub/namespaces/ns/authorizationRules/rule"
        log_categories                           = ["AppEvents"]
        logs = [
          { category_group = "allLogs" },
        ]
      }
    }
  }

  expect_failures = [var.diagnostic_settings_v2]
}
