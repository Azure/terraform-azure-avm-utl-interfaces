locals {
  # Create a map of role assignment names based on the principal ID and role definition resource ID.
  role_assignment_deterministic_name = {
    for k, v in var.role_assignments : k => {
      # mimic the random_uuid attribute value
      result = uuidv5("url", format("%s%s", v.principal_id, local.role_assignments_role_name_to_resource_id[v.role_definition_id_or_name]))
    }
  }
  role_assignment_private_endpoint_deterministic_name = {
    for k, v in local.role_assignments_private_endpoint_azapi_keys_only : k => {
      # mimic the random_uuid attribute value
      result = uuidv5("url", format(
        "%s%s",
        var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].principal_id,
        local.role_assignments_private_endpoint_role_definition_resource_ids[k]
      ))
    }
  }
  # Here is the role assignment data for the azapi_resource.
  role_assignments_azapi = {
    for k, v in var.role_assignments : k => {
      type = local.role_assignments_type
      name = lookup(random_uuid.role_assignment_name, k, local.role_assignment_deterministic_name[k]).result
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
  role_assignments_private_endpoint_azapi = {
    for k, v in local.role_assignments_private_endpoint_azapi_keys_only : k => {
      pe_key         = v.pe_key
      assignment_key = v.assignment_key
      type           = local.role_assignments_type
      name           = lookup(random_uuid.role_assignment_name_private_endpoint, k, local.role_assignment_private_endpoint_deterministic_name[k]).result
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
  role_assignments_private_endpoint_role_definition_resource_ids = {
    for k, v in local.role_assignments_private_endpoint_azapi_keys_only : k => lookup(
      local.role_assignments_role_name_to_resource_id,
      var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name,
      var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name
    )
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
  role_assignments_role_name_to_resource_id = var.role_assignment_definition_lookup_enabled ? {
    for res in data.azapi_resource_list.role_definitions[0].output.results : res.role_name => res.id
  } : {}
  # The type and api version of the role assignments resource.
  role_assignments_type = "Microsoft.Authorization/roleAssignments@2022-04-01"
}
