locals {
  # Here is the role assignment data for the azapi_resource.
  role_assignments_azapi = {
    for k, v in var.role_assignments : k => {
      name = coalesce(v.role_assignment_name, random_uuid.role_assignment_name[k].result)
      type = local.role_assignments_type
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

  # Merge user-supplied configuration with Azure-returned values to prevent drift.
  # Azure automatically infers principalType and returns fully qualified roleDefinitionId paths.
  # We prefer user-supplied values where provided, but accept Azure's values for drift-prone fields.
  role_assignments_merged = {
    for k, v in data.azapi_resource.role_assignments : k => {
      principalId                        = local.role_assignments_azapi[k].body.properties.principalId
      roleDefinitionId                   = v.output.properties.roleDefinitionId # Use Azure's normalized path
      conditionVersion                   = local.role_assignments_azapi[k].body.properties.conditionVersion
      condition                          = local.role_assignments_azapi[k].body.properties.condition
      description                        = local.role_assignments_azapi[k].body.properties.description
      principalType                      = v.output.properties.principalType # Use Azure's inferred value
      delegatedManagedIdentityResourceId = local.role_assignments_azapi[k].body.properties.delegatedManagedIdentityResourceId
    }
  }

  # The role assignments for private endpoints.
  # We reference the variable to avoid cycle errors.
  role_assignments_private_endpoint_azapi = {
    for k, v in local.role_assignments_private_endpoint_azapi_keys_only : k => {
      pe_key         = v.pe_key
      assignment_key = v.assignment_key
      name           = random_uuid.role_assignment_name_private_endpoint[k].result
      type           = local.role_assignments_type
      body = {
        properties = {
          principalId                        = var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].principal_id
          roleDefinitionId                   = local.role_assignments_private_endpoint_role_definition_resource_ids[k]
          conditionVersion                   = lookup(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key], "condition_version", null)
          condition                          = lookup(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key], "condition", null)
          description                        = lookup(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key], "description", null)
          principalType                      = lookup(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key], "principal_type", null)
          delegatedManagedIdentityResourceId = lookup(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key], "delegated_managed_identity_resource_id", null)
        }
      }
    }
  }

  # Merge user-supplied configuration with Azure-returned values for private endpoint role assignments.
  # Same drift prevention logic as above, applied to private endpoint role assignments.
  role_assignments_private_endpoint_merged = {
    for k, v in data.azapi_resource.role_assignments_private_endpoint : k => {
      principalId                        = local.role_assignments_private_endpoint_azapi[k].body.properties.principalId
      roleDefinitionId                   = v.output.properties.roleDefinitionId # Use Azure's normalized path
      conditionVersion                   = local.role_assignments_private_endpoint_azapi[k].body.properties.conditionVersion
      condition                          = local.role_assignments_private_endpoint_azapi[k].body.properties.condition
      description                        = local.role_assignments_private_endpoint_azapi[k].body.properties.description
      principalType                      = v.output.properties.principalType # Use Azure's inferred value
      delegatedManagedIdentityResourceId = local.role_assignments_private_endpoint_azapi[k].body.properties.delegatedManagedIdentityResourceId
    }
  }

  # Create a flattened map of role assignments for private endpoints.
  # Only include keys to avoid cycle errors.
  role_assignments_private_endpoint_azapi_keys_only = {
    for pe_assignment in flatten([
      for pe_key, pe_val in var.private_endpoints : [
        for ra_key, _ in pe_val.role_assignments : {
          pe_key         = pe_key
          assignment_key = ra_key
        }
      ]
      ]) : "${pe_assignment.pe_key}-${pe_assignment.assignment_key}" => {
      pe_key         = pe_assignment.pe_key
      assignment_key = pe_assignment.assignment_key
    }
  }
  # Create a map of role definition resource ids for each role assignment for private endpoints.
  role_assignments_private_endpoint_role_definition_resource_ids = {
    for k, v in local.role_assignments_private_endpoint_azapi_keys_only : k => lookup(
      module.role_definitions.role_definition_rolename_to_resource_id,
      var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name,
      var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name
    )
  }
  # Create a map of role definition resource ids for each role assignment.
  role_assignments_role_definition_resource_ids = {
    for k, v in var.role_assignments : k => lookup(
      module.role_definitions.role_definition_rolename_to_resource_id,
      v.role_definition_id_or_name,
      v.role_definition_id_or_name
    )
  }
  role_assignments_type = "Microsoft.Authorization/roleAssignments@2022-04-01"
}
