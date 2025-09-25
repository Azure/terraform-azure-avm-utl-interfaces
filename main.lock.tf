
locals {
  lock_type = "Microsoft.Authorization/locks@2020-05-01"
}

resource "azapi_resource" "lock" {
  count = local.lock_azapi != null ? 1 : 0

  name           = local.lock_azapi.name
  parent_id      = var.this_resource_id
  type           = local.lock_type
  body           = local.lock_azapi.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    azapi_resource.role_assignments,
    azapi_resource.role_assignments_private_endpoint,
    azapi_resource.private_endpoints,
    azapi_resource.private_dns_zone_groups,
  ]
}

resource "azapi_resource" "lock_private_endpoint" {
  for_each = local.lock_private_endpoint_azapi

  name           = each.value.name
  parent_id      = azapi_resource.private_endpoints[each.value.pe_key].id
  type           = local.lock_type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  depends_on = [
    # Put everything in here
  ]
}
