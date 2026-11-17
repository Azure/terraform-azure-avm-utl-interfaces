locals {
  role_assignment_definition_guid_pattern               = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
  role_assignment_definition_tenant_resource_id_pattern = "(?i)^/providers/Microsoft\\.Authorization/roleDefinitions/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$"
  role_assignment_definition_subscription_id = var.role_assignment_definition_scope == null ? null : try(
    regexall("(?i)^/subscriptions/([^/]+)($|/)", var.role_assignment_definition_scope)[0][0],
    null
  )
  # Should we use the role assignment definition lookup data source?
  role_assignment_definition_lookup_enabled = var.role_assignment_definition_lookup_enabled && (
    length(var.role_assignments) > 0 || length(local.role_assignments_private_endpoint_azapi_keys_only) > 0
  )
  # Here is the role assignment data for the azapi_resource.
  # The name is taken from the `name` attribute when supplied, otherwise a random UUID is generated.
  role_assignments_azapi = {
    for k, v in var.role_assignments : k => {
      type = local.role_assignments_type
      name = coalesce(v.name, random_uuid.role_assignment_name[k].result)
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
  # The role assignments for private endpoints.
  # We reference the variable to avoid cycle errors.
  role_assignments_private_endpoint_azapi = {
    for k, v in local.role_assignments_private_endpoint_azapi_keys_only : k => {
      pe_key         = v.pe_key
      assignment_key = v.assignment_key
      type           = local.role_assignments_type
      name = coalesce(
        var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].name,
        random_uuid.role_assignment_name_private_endpoint[k].result
      )
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
  # Create a map of role definition resource ids for each role assignment for private endpoints.
  role_assignments_private_endpoint_role_definition_resource_ids = {
    for k, v in local.role_assignments_private_endpoint_azapi_keys_only : k => (
      local.role_assignment_definition_subscription_id != null && can(regex(
        local.role_assignment_definition_tenant_resource_id_pattern,
        var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name
        )) ? format(
        "/subscriptions/%s/providers/Microsoft.Authorization/roleDefinitions/%s",
        local.role_assignment_definition_subscription_id,
        lower(regex(
          local.role_assignment_definition_tenant_resource_id_pattern,
          var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name
        )[0])
        ) : startswith(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name, "/") || can(regex(
          local.role_assignment_definition_guid_pattern,
          var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name
        )) ? var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name : try(
        one(distinct(try(
          local.role_assignments_role_name_to_resource_ids[lower(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name)],
          []
        ))),
        null
      )
    )
  }
  # Create a map of role definition resource ids for each role assignment.
  role_assignments_role_definition_resource_ids = {
    for k, v in var.role_assignments : k => (
      local.role_assignment_definition_subscription_id != null && can(regex(
        local.role_assignment_definition_tenant_resource_id_pattern,
        v.role_definition_id_or_name
        )) ? format(
        "/subscriptions/%s/providers/Microsoft.Authorization/roleDefinitions/%s",
        local.role_assignment_definition_subscription_id,
        lower(regex(local.role_assignment_definition_tenant_resource_id_pattern, v.role_definition_id_or_name)[0])
        ) : startswith(v.role_definition_id_or_name, "/") || can(regex(
          local.role_assignment_definition_guid_pattern,
          v.role_definition_id_or_name
        )) ? v.role_definition_id_or_name : try(
        one(distinct(try(
          local.role_assignments_role_name_to_resource_ids[lower(v.role_definition_id_or_name)],
          []
        ))),
        null
      )
    )
  }
  role_assignments_ambiguous_role_definition_names = {
    for k, v in var.role_assignments : k => v.role_definition_id_or_name
    if local.role_assignment_definition_lookup_enabled &&
    !startswith(v.role_definition_id_or_name, "/") &&
    !can(regex(local.role_assignment_definition_guid_pattern, v.role_definition_id_or_name)) &&
    length(distinct(try(local.role_assignments_role_name_to_resource_ids[lower(v.role_definition_id_or_name)], []))) > 1
  }
  role_assignments_private_endpoint_ambiguous_role_definition_names = {
    for k, v in local.role_assignments_private_endpoint_azapi_keys_only : k => var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name
    if local.role_assignment_definition_lookup_enabled &&
    !startswith(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name, "/") &&
    !can(regex(local.role_assignment_definition_guid_pattern, var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name)) &&
    length(distinct(try(local.role_assignments_role_name_to_resource_ids[lower(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name)], []))) > 1
  }
  role_assignments_private_endpoint_unresolved_role_definition_names = {
    for k, v in local.role_assignments_private_endpoint_azapi_keys_only : k => var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name
    if !startswith(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name, "/") &&
    !can(regex(local.role_assignment_definition_guid_pattern, var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name)) &&
    (!local.role_assignment_definition_lookup_enabled || length(distinct(try(local.role_assignments_role_name_to_resource_ids[lower(var.private_endpoints[v.pe_key].role_assignments[v.assignment_key].role_definition_id_or_name)], []))) == 0)
  }
  role_assignments_unresolved_role_definition_names = {
    for k, v in var.role_assignments : k => v.role_definition_id_or_name
    if !startswith(v.role_definition_id_or_name, "/") &&
    !can(regex(local.role_assignment_definition_guid_pattern, v.role_definition_id_or_name)) &&
    (!local.role_assignment_definition_lookup_enabled || length(distinct(try(local.role_assignments_role_name_to_resource_ids[lower(v.role_definition_id_or_name)], []))) == 0)
  }
  # Take the output from the data source and group resource ids by case-insensitive role name.
  # But only if the lookup is enabled.
  role_assignments_role_name_to_resource_ids = local.role_assignment_definition_lookup_enabled ? {
    for res in data.azapi_resource_list.role_definitions[0].output.results : lower(res.role_name) => (
      local.role_assignment_definition_subscription_id != null && can(regex(local.role_assignment_definition_tenant_resource_id_pattern, res.id)) ? format(
        "/subscriptions/%s/providers/Microsoft.Authorization/roleDefinitions/%s",
        local.role_assignment_definition_subscription_id,
        lower(regex(local.role_assignment_definition_tenant_resource_id_pattern, res.id)[0])
      ) : res.id
    )...
  } : {}
  # The type and api version of the role assignments resource.
  role_assignments_type = "Microsoft.Authorization/roleAssignments@2022-04-01"
}
