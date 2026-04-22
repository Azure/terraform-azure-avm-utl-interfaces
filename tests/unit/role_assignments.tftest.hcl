mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

# Reproduces the original crash: a full role definition resource ID is supplied as
# role_definition_id_or_name. With role_assignment_name_use_random_uuid = true the
# deterministic name path should not be evaluated as a hard map index.
run "role_assignment_resource_id_with_random_uuid" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
    role_assignment_name_use_random_uuid      = true
    role_assignments = {
      ra1 = {
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
  }

  assert {
    error_message = "Role assignment roleDefinitionId should pass through the full resource ID."
    condition     = output.role_assignments_azapi["ra1"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }
}

# Same as above but with deterministic name path actually used.
run "role_assignment_resource_id_with_deterministic_name" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
    role_assignment_name_use_random_uuid      = false
    role_assignments = {
      ra1 = {
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
  }

  assert {
    error_message = "Role assignment roleDefinitionId should pass through the full resource ID."
    condition     = output.role_assignments_azapi["ra1"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }

  assert {
    error_message = "Deterministic role assignment name should match uuidv5 of principal_id + role definition resource ID."
    condition = output.role_assignments_azapi["ra1"].name == uuidv5(
      "url",
      "00000000-0000-0000-0000-000000000001/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
    )
  }
}

# Same scenarios for private endpoint role assignments.
run "private_endpoint_role_assignment_resource_id_with_random_uuid" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
    role_assignment_name_use_random_uuid      = true
    private_endpoints_scope                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sa"
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        role_assignments = {
          ra1 = {
            role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
            principal_id               = "00000000-0000-0000-0000-000000000001"
          }
        }
      }
    }
  }

  assert {
    error_message = "Private endpoint role assignment roleDefinitionId should pass through the full resource ID."
    condition     = output.role_assignments_private_endpoint_azapi["pe1-ra1"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }
}

run "private_endpoint_role_assignment_resource_id_with_deterministic_name" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
    role_assignment_name_use_random_uuid      = false
    private_endpoints_scope                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sa"
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        role_assignments = {
          ra1 = {
            role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
            principal_id               = "00000000-0000-0000-0000-000000000001"
          }
        }
      }
    }
  }

  assert {
    error_message = "Private endpoint role assignment roleDefinitionId should pass through the full resource ID."
    condition     = output.role_assignments_private_endpoint_azapi["pe1-ra1"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }

  assert {
    error_message = "Deterministic private endpoint role assignment name should match uuidv5 of principal_id + role definition resource ID."
    condition = output.role_assignments_private_endpoint_azapi["pe1-ra1"].name == uuidv5(
      "url",
      "00000000-0000-0000-0000-000000000001/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
    )
  }
}
