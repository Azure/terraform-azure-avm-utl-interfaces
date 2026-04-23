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

# A full role definition resource ID supplied as role_definition_id_or_name should
# pass through unchanged. The role assignment name comes from the random_uuid resource.
run "role_assignment_resource_id_with_random_uuid" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
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

# When the optional `name` attribute is supplied, it should override the random UUID.
run "role_assignment_name_override" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
    role_assignments = {
      ra1 = {
        name                       = "11111111-1111-1111-1111-111111111111"
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
  }

  assert {
    error_message = "Role assignment name should be overridden by the `name` attribute when supplied."
    condition     = output.role_assignments_azapi["ra1"].name == "11111111-1111-1111-1111-111111111111"
  }
}

# Same scenarios for private endpoint role assignments.
run "private_endpoint_role_assignment_resource_id_with_random_uuid" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
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

# When the optional `name` attribute is supplied on a private endpoint role assignment, it should
# override the random UUID.
run "private_endpoint_role_assignment_name_override" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
    private_endpoints_scope                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sa"
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        role_assignments = {
          ra1 = {
            name                       = "22222222-2222-2222-2222-222222222222"
            role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
            principal_id               = "00000000-0000-0000-0000-000000000001"
          }
        }
      }
    }
  }

  assert {
    error_message = "Private endpoint role assignment name should be overridden by the `name` attribute when supplied."
    condition     = output.role_assignments_private_endpoint_azapi["pe1-ra1"].name == "22222222-2222-2222-2222-222222222222"
  }
}
