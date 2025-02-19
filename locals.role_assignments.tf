locals {
  # Here is the role assignment data for the azapi_resource.
  role_assignments_azapi = {
    for k, v in var.role_assignments : k => {
      type = local.role_assignments_type
      name = uuidv5("url", format("%s%s", v.principal_id, local.role_assignments_role_definition_resource_ids[k]))
      body = {
        properties = {
          principalId                        = v.principal_id
          roleDefinitionId                   = local.role_assignments_role_definition_resource_ids[k]
          conditionVersion                   = lookup(v, "condition_version", null)
          condition                          = lookup(v, "condition", null)
          description                        = lookup(v, "description", null)
          principalType                      = lookup(v, "principal_type", null)
          delegatedManagedIdentityResourceId = lookup(v, "delegated_managed_identity_resource_id", null)
        }
      }
    }
  }
  # Create a map of role definition resource ids for each role assignment.
  # We do this because we use this information more than once.
  # Firstly in the roleDefinitionId property of the role assignment,
  # and secondly as part of the deterministic UUID name property of the role assignment.
  role_assignments_role_definition_resource_ids = {
    for k, v in var.role_assignments : k => lookup(
      local.role_assignments_role_name_to_resource_id,
      v.role_definition_id_or_name,
      v.role_definition_id_or_name
    )
  }
  # Take the output from the data source and create a map of role_name to resource id.
  role_assignments_role_name_to_resource_id = var.role_assignment_definition_lookup_enabled && length(var.role_assignments) ? {
    for res in data.azapi_resource_list.role_definitions[0].output.results : res.role_name => res.id
  } : {}

  # The type and api version of the role assignments resource.
  role_assignments_type = "Microsoft.Authorization/roleAssignments@2022-04-01"
}
