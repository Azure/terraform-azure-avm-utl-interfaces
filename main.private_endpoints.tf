locals {
  private_endpoints_type = "Microsoft.Network/privateEndpoints@2024-05-01"
}
resource "azapi_resource" "private_endpoints" {
  for_each = local.private_endpoints

  location       = var.location
  name           = each.value.name
  parent_id      = coalesce(var.private_endpoints[each.key].resource_group_resource_id, var.parent_id)
  type           = local.private_endpoints_type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry = {
    error_message_regex = ["ScopeLocked"]
  }
  tags           = each.value.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    delete = "5m"
  }
}

resource "azapi_resource" "private_endpoint_locks" {
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
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoint_role_assignments
  ]
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = local.private_dns_zone_groups

  name           = each.value.name
  parent_id      = azapi_resource.private_endpoints[each.key].id
  type           = local.private_dns_zone_group_type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry = {
    error_message_regex = ["ScopeLocked"]
  }
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    delete = "5m"
  }
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = local.role_assignments_private_endpoint_azapi

  name           = each.value.name
  parent_id      = azapi_resource.private_endpoints[each.value.pe_key].id
  type           = local.role_assignments_type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  retry = {
    error_message_regex = ["ScopeLocked"]
  }
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  timeouts {
    delete = "5m"
  }
}
