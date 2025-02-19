# This resource allows us to look up role definitions by role name.
# The AzureRM provider does this already so we are replicating this functionality here to benefit AzAPI users.
data "azapi_resource_list" "role_definitions" {
  count = var.role_assignment_definition_lookup_enabled && length(var.role_assignment_definition_scope) > 0 ? 1 : 0

  parent_id = var.role_assignment_definition_scope == null ? "/" : var.role_assignment_definition_scope
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}
