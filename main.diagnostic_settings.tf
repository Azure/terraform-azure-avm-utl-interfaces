# The diagnostic settings API uses lists of objects for logs and metrics.
# Some Azure services add entries automatically (often disabled), causing Terraform drift.
#
# With azapi >= 2.9 (PR #1033), this is solved using:
# - list_unique_id_property: tells azapi how to match list items by key (category/categoryGroup)
# - ignore_other_items_in_list: tells azapi to leave server-added entries alone
resource "azapi_resource" "diagnostic_settings" {
  for_each = local.diagnostic_settings_azapi

  name                   = each.value.name
  parent_id              = var.this_resource_id
  type                   = local.diagnostic_settings_type
  body                   = each.value.body
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_null_property   = true
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  list_unique_id_property = {
    "properties.logs"    = "categoryGroup, category"
    "properties.metrics" = "category"
  }
  ignore_other_items_in_list = [
    "properties.logs",
    "properties.metrics",
  ]
}
