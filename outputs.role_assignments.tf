output "role_assignments_azapi" {
  description = <<DESCRIPTION
A map of role assignments for use in azapi_resource, the value is an object containing the following attributes:

- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.
DESCRIPTION

  precondition {
    condition     = length(local.role_assignments_unresolved_role_definition_names) == 0
    error_message = "The following role assignments use role names that could not be resolved: ${join(", ", [for k, v in local.role_assignments_unresolved_role_definition_names : "${k} (${v})"])}. Supply existing role names with role definition lookup enabled and a lookup scope, or supply role definition resource IDs or GUIDs."
  }
  precondition {
    condition     = length(local.role_assignments_ambiguous_role_definition_names) == 0
    error_message = "The following role assignments use role names that match multiple role definitions case-insensitively: ${join(", ", [for k, v in local.role_assignments_ambiguous_role_definition_names : "${k} (${v})"])}. Supply unambiguous role definition resource IDs or GUIDs."
  }
  value = local.role_assignments_azapi
}

output "role_assignments_private_endpoint_azapi" {
  description = <<DESCRIPTION
A flattened map of role assignments for private endpoints, the value is an object containing the following attributes:

- `pe_key` - The key of the private endpoint, used to look up the parent id.
- `assignment_key` - The key of the role assignment from the private endpoint object map.
- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.

These role assignments should be used for private endpoints defined in var.private_endpoints.
DESCRIPTION

  precondition {
    condition     = length(local.role_assignments_private_endpoint_unresolved_role_definition_names) == 0
    error_message = "The following private endpoint role assignments use role names that could not be resolved: ${join(", ", [for k, v in local.role_assignments_private_endpoint_unresolved_role_definition_names : "${k} (${v})"])}. Supply existing role names with role definition lookup enabled and a lookup scope, or supply role definition resource IDs or GUIDs."
  }
  precondition {
    condition     = length(local.role_assignments_private_endpoint_ambiguous_role_definition_names) == 0
    error_message = "The following private endpoint role assignments use role names that match multiple role definitions case-insensitively: ${join(", ", [for k, v in local.role_assignments_private_endpoint_ambiguous_role_definition_names : "${k} (${v})"])}. Supply unambiguous role definition resource IDs or GUIDs."
  }
  value = local.role_assignments_private_endpoint_azapi
}
