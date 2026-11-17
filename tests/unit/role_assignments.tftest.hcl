mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
            role_name = "Storage Blob Data Reader"
          },
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/11111111-1111-1111-1111-111111111111"
            role_name = "Ambiguous Role"
          },
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/22222222-2222-2222-2222-222222222222"
            role_name = "AMBIGUOUS ROLE"
          }
        ]
      }
    }
  }
}

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
    location = "eastus"
  }

  assert {
    error_message = "Role assignment roleDefinitionId should pass through the full resource ID."
    condition     = output.role_assignments_azapi["ra1"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }

  assert {
    error_message = "An omitted role assignment name should continue to use the existing keyed random_uuid resource value."
    condition = (
      keys(output.role_assignments_azapi) == ["ra1"] &&
      output.role_assignments_azapi["ra1"].name == random_uuid.role_assignment_name["ra1"].result
    )
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
    location = "eastus"
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
    location = "eastus"
  }

  assert {
    error_message = "Private endpoint role assignment roleDefinitionId should pass through the full resource ID."
    condition     = output.role_assignments_private_endpoint_azapi["pe1-ra1"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }

  assert {
    error_message = "An omitted private endpoint role assignment name should continue to use the existing keyed random_uuid resource value."
    condition = (
      keys(output.role_assignments_private_endpoint_azapi) == ["pe1-ra1"] &&
      output.role_assignments_private_endpoint_azapi["pe1-ra1"].name == random_uuid.role_assignment_name_private_endpoint["pe1-ra1"].result
    )
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
    location = "eastus"
  }

  assert {
    error_message = "Private endpoint role assignment name should be overridden by the `name` attribute when supplied."
    condition     = output.role_assignments_private_endpoint_azapi["pe1-ra1"].name == "22222222-2222-2222-2222-222222222222"
  }
}

run "role_assignment_name_resolution_is_case_insensitive" {
  command = apply

  variables {
    role_assignment_definition_scope = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
    role_assignments = {
      ra1 = {
        role_definition_id_or_name = "storage blob data reader"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
    location = "eastus"
  }

  assert {
    error_message = "Role assignment names should resolve case-insensitively through the shared lookup."
    condition     = output.role_assignments_azapi["ra1"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }
}

run "private_endpoint_role_assignment_name_resolution_is_case_insensitive" {
  command = apply

  variables {
    role_assignment_definition_scope = "/subscriptions/00000000-0000-0000-0000-000000000000"
    private_endpoints_scope          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sa"
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        role_assignments = {
          ra1 = {
            role_definition_id_or_name = "STORAGE BLOB DATA READER"
            principal_id               = "00000000-0000-0000-0000-000000000001"
          }
        }
      }
    }
    location = "eastus"
  }

  assert {
    error_message = "Private endpoint role assignment names should resolve case-insensitively through the shared lookup."
    condition     = output.role_assignments_private_endpoint_azapi["pe1-ra1"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }
}

run "scoped_tenant_role_definition_id_is_normalized" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
    role_assignment_definition_scope          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg"
    role_assignments = {
      tenant_id = {
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/2A2B9908-6EA1-4AE2-8E65-A410DF84E7D1"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
      cross_subscription_id = {
        role_definition_id_or_name = "/subscriptions/33333333-3333-3333-3333-333333333333/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
        principal_id               = "00000000-0000-0000-0000-000000000002"
      }
      guid = {
        role_definition_id_or_name = "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
        principal_id               = "00000000-0000-0000-0000-000000000003"
      }
    }
    location = "eastus"
  }

  assert {
    error_message = "Tenant-form role definition IDs should be qualified by the explicit subscription scope."
    condition     = output.role_assignments_azapi["tenant_id"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }

  assert {
    error_message = "Already subscription-qualified role definition IDs should remain unchanged, including cross-subscription IDs."
    condition     = output.role_assignments_azapi["cross_subscription_id"].body.properties.roleDefinitionId == "/subscriptions/33333333-3333-3333-3333-333333333333/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }

  assert {
    error_message = "GUID role definition identifiers should remain unchanged."
    condition     = output.role_assignments_azapi["guid"].body.properties.roleDefinitionId == "2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }
}

run "private_endpoint_scoped_tenant_role_definition_id_is_normalized" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
    role_assignment_definition_scope          = "/subscriptions/00000000-0000-0000-0000-000000000000"
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
    location = "eastus"
  }

  assert {
    error_message = "Private endpoint tenant-form role definition IDs should be qualified by the explicit subscription scope."
    condition     = output.role_assignments_private_endpoint_azapi["pe1-ra1"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }
}

run "management_group_scope_preserves_tenant_role_definition_id" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
    role_assignment_definition_scope          = "/providers/Microsoft.Management/managementGroups/example"
    role_assignments = {
      ra1 = {
        role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
    location = "eastus"
  }

  assert {
    error_message = "Management-group scopes must not add an arbitrary subscription to tenant-form role definition IDs."
    condition     = output.role_assignments_azapi["ra1"].body.properties.roleDefinitionId == "/providers/Microsoft.Authorization/roleDefinitions/2a2b9908-6ea1-4ae2-8e65-a410df84e7d1"
  }
}

run "unresolved_role_assignment_name_fails" {
  command = plan

  variables {
    role_assignment_definition_scope = "/subscriptions/00000000-0000-0000-0000-000000000000"
    role_assignments = {
      ra1 = {
        role_definition_id_or_name = "Missing Role"
        principal_id               = "00000000-0000-0000-0000-000000000001"
      }
    }
    location = "eastus"
  }

  expect_failures = [
    output.role_assignments_azapi,
  ]
}

run "ambiguous_private_endpoint_role_assignment_name_fails" {
  command = plan

  variables {
    role_assignment_definition_scope = "/subscriptions/00000000-0000-0000-0000-000000000000"
    private_endpoints_scope          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sa"
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        role_assignments = {
          ra1 = {
            role_definition_id_or_name = "ambiguous role"
            principal_id               = "00000000-0000-0000-0000-000000000001"
          }
        }
      }
    }
    location = "eastus"
  }

  expect_failures = [
    output.role_assignments_private_endpoint_azapi,
  ]
}
