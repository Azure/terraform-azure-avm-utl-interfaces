# Deprecated locals to maintain backwards compatibility and support simple removal of deprecated variables.
locals {
  logs_deprecated = {
    for k, v in var.diagnostic_settings : k => setunion(
      [
        for log_group in v.log_groups : {
          category      = null
          categoryGroup = log_group
          enabled       = true
        }
      ],
      [
        for log_category in v.log_categories : {
          category      = log_category
          categoryGroup = null
          enabled       = true
        }
      ]
    )
  }
  metrics_deprecated = {
    for k, v in var.diagnostic_settings : k => length(v.metric_categories) > 0 ? [
      for category in v.metric_categories :
      {
        category = category
        enabled  = true
      }
    ] : null
  }
}

# New logs and metrics locals for full API compatibility.
locals {
  logs = {
    for k, v in var.diagnostic_settings : k => length(v.logs) > 0 ? [
      for log in v.logs :
      {
        category      = log.category
        categoryGroup = log.category_group
        enabled       = log.enabled
        retentionPolicy = {
          days    = log.retention_policy.days
          enabled = log.retention_policy.enabled
        }
      }
    ] : null
  }
  metrics = {
    for k, v in var.diagnostic_settings : k => length(v.metrics) > 0 ? [
      for metric in v.metrics :
      {
        category = metric.category
        enabled  = metric.enabled
        retentionPolicy = {
          days    = metric.retention_policy.days
          enabled = metric.retention_policy.enabled
        }
      }
    ] : null
  }
}

# These locals create the data for the azapi_resources from the var.diagnostic_settings variable
locals {
  diagnostic_settings_azapi = {
    for k, v in var.diagnostic_settings : k => {
      type = local.diagnostic_settings_type
      name = v.name
      body = {
        properties = {
          eventHubAuthorizationRuleId = lookup(v, "event_hub_authorization_rule_resource_id", null)
          eventHubName                = lookup(v, "event_hub_name", null)
          logAnalyticsDestinationType = lookup(v, "log_analytics_destination_type", null)
          logs                        = length(local.logs[k]) > 0 ? local.logs[k] : local.logs_deprecated[k]
          marketplacePartnerId        = lookup(v, "marketplace_partner_resource_id", null)
          metrics                     = length(local.metrics[k]) > 0 ? local.metrics[k] : local.metrics_deprecated[k]
          storageAccountId            = lookup(v, "storage_account_resource_id", null)
          workspaceId                 = lookup(v, "workspace_resource_id", null)
        }
      }
    }
  }
  diagnostic_settings_type = "Microsoft.Insights/diagnosticSettings@2021-05-01-preview"
}
