# This module allows us to look up role definitions by role name.
# The AzureRM provider does this already so we are replicating this functionality here to benefit AzAPI users.
module "role_definitions" {
  source  = "Azure/avm-utl-roledefinitions/azure"
  version = "0.0.2"

  enable_telemetry      = var.enable_telemetry
  role_definition_scope = var.this_resource_id
  use_cached_data       = !var.role_assignment_definition_lookup_use_live_data
}

# Use a random UUID for the role assignment name if the variable is set to true.
# This is the recommended way to create role assignment names to avoid issues with duplicate UUIDs
# and unknown values causing replacement, e.g. principal ID.
resource "random_uuid" "role_assignment_name" {
  for_each = var.role_assignments
}

# Use a random UUID for the role assignment name if the variable is set to true.
# This is the recommended way to create role assignment names to avoid issues with duplicate UUIDs
# and unknown values causing replacement, e.g. principal ID.
resource "random_uuid" "role_assignment_name_private_endpoint" {
  for_each = local.role_assignments_private_endpoint_azapi_keys_only
}

resource "azapi_resource" "role_assignments" {
  for_each = local.role_assignments_azapi

  name           = each.value.name
  parent_id      = var.this_resource_id
  type           = each.value.type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

resource "azapi_resource" "role_assignments_private_endpoint" {
  for_each = local.role_assignments_private_endpoint_azapi

  name           = each.value.name
  parent_id      = coalesce(azapi_resource.private_endpoints[each.value.pe_key].resource_group_resource_id, var.parent_id)
  type           = each.value.type
  body           = each.value.body
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
