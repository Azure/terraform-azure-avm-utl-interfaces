variable "diagnostic_settings" {
  type = map(object({
    name = optional(string, null)
    logs = optional(set(object({
      category       = optional(string, null)
      category_group = optional(string, null)
      enabled        = optional(bool, true)
      retention_policy = optional(object({
        days    = optional(number, 0)
        enabled = optional(bool, false)
      }))
    })), [])
    metrics = optional(set(object({
      category = optional(string, null)
      enabled  = optional(bool, true)
      retention_policy = optional(object({
        days    = optional(number, 0)
        enabled = optional(bool, false)
      }))
    })), [])
    log_analytics_destination_type           = optional(string, "Dedicated")
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
  - `logs` - (Optional) A set of log objects to send to the log analytics workspace. See logs heading below. Defaults to `[]`.
  - `metrics` - (Optional) A set of metric objects to send to the log analytics workspace. See metrics heading below. Defaults to `[]`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

  ### Logs
  - `category` - (Optional) The name of the log category to send to the log analytics workspace. The values for this field are dependent on the resource type and can be found in the Azure documentation, but always include `AllLogs`.
  - `category_group` - (Optional) The name of the log category group to send to the log analytics workspace. The values for this field are dependent on the resource type and can be found in the Azure documentation.
  - `enabled` - (Optional) Whether the log category is enabled. Defaults to `true`.
  - `retention_policy` - (Optional) The retention policy for the log category. If not set, the retention policy will be set to `0` days and `false`
    for `days` and `enabled` respectively.

  ### Metrics
  - `category` - (Optional) The name of the metric category to send to the log analytics workspace. The values for this field are dependent on the resource type and can be found in the Azure documentation, but always include `AllMetrics`.
  - `enabled` - (Optional) Whether the metric category is enabled. Defaults to `true`.
  - `retention_policy` - (Optional) The retention policy for the metric category. If not set, the retention policy will be set to `0` days and `false`
    for `days` and `enabled` respectively.
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
  # validation {
  #   condition = alltrue(
  #     [
  #       for _, v in var.diagnostic_settings :
  #       !(length(v.log_categories) > 0 && length(v.log_groups) > 0)
  #     ]
  #   )
  #   error_message = "Log categories and log groups cannot be set at the same time."
  # }
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
