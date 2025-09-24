variable "diagnostic_settings" {
  type = map(object({
    name              = optional(string, null)
    log_categories    = optional(set(string), [])
    log_groups        = optional(set(string), ["allLogs"])
    metric_categories = optional(set(string), ["AllMetrics"])
    logs = optional(list(object({
      category       = optional(string, null)
      category_group = optional(string, null)
      enabled        = optional(bool, true)
      retention_policy = optional(object({
        days    = optional(number, 0)
        enabled = optional(bool, false)
      }), {})
    })), [])
    metrics = optional(list(object({
      category = optional(string, null)
      enabled  = optional(bool, true)
      retention_policy = optional(object({
        days    = optional(number, 0)
        enabled = optional(bool, false)
      }), {})
    })), [])
    log_analytics_destination_type           = optional(string, null)
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of diagnostic settings to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `log_categories` - (Optional) DEPRECATED - use `logs` instead, set to empty set `[]` if you do not want logs. A set of log categories to send to the log analytics workspace. Defaults to `[]`.
  - `log_groups` - (Optional) DEPRECATED - use `logs` instead. A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
  - `logs` - (Optional) A list of log settings to send to the log analytics workspace.
    - `category` - (Optional) The category of log to send. Either `category` or `category_group` must be set.
    - `category_group` - (Optional) The category group of logs to send. Either `category` or `category_group` must be set.
    - `enabled` - (Optional) Whether the log setting is enabled. Defaults to `true`.
    - `retention_policy` - (Optional) The retention policy for the log setting.
      - `days` - (Optional) The number of days to retain the logs for. A value of 0 means that logs are retained indefinitely. Defaults to `0`.
      - `enabled` - (Optional) Whether the retention policy is enabled. Defaults to `false`.
  - `metric_categories` - (Optional) DEPRECATED - use `metrics` instead, set to an empty set `[]` if you do not want metrics. A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
  - `metrics` - (Optional) A list of metric settings to send to the log analytics workspace.
    - `category` - (Optional) The category of metric to send.
    - `enabled` - (Optional) Whether the metric setting is enabled. Defaults to `true`.
    - `retention_policy` - (Optional) The retention policy for the metric setting.
      - `days` - (Optional) The number of days to retain the metrics for. A value of 0 means that metrics are retained indefinitely. Defaults to `0`.
      - `enabled` - (Optional) Whether the retention policy is enabled. Defaults to `false`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
  DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)
      ]
    )
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        !(length(v.log_categories) > 0 && length(v.log_groups) > 0)
      ]
    )
    error_message = "Log categories and log groups cannot be set at the same time."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}
