
locals {
  lock_type = "Microsoft.Authorization/locks@2020-05-01"
}

# resource "terraform_data" "lock_dependency" {
#   count = local.lock_azapi != null ? 1 : 0

#   input = var.lock_dependency_input
# }

resource "azapi_resource" "lock" {
  count = local.lock_azapi != null ? 1 : 0

  name                   = local.lock_azapi.name
  parent_id              = var.this_resource_id
  type                   = local.lock_type
  body                   = local.lock_azapi.body
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoints,
    azapi_resource.role_assignments_private_endpoint,
    azapi_resource.role_assignments,
    azapi_update_resource.diagnostic_settings,
    #terraform_data.lock_dependency,
  ]
}

resource "azapi_resource" "lock_private_endpoint" {
  for_each = local.lock_private_endpoint_azapi

  name                   = each.value.name
  parent_id              = azapi_resource.private_endpoints[each.value.pe_key].id
  type                   = local.lock_type
  body                   = each.value.body
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = []
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.private_dns_zone_groups,
  ]
}
