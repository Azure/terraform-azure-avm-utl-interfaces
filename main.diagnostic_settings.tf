resource "azapi_resource" "diagnostic_settings" {
  for_each  = local.diagnostic_settings_azapi
  type      = local.diagnostic_settings_type
  name      = each.value.name
  parent_id = var.this_resource_id
  body      = each.value.body
}
