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

run "top_level_lock_without_notes" {
  command = apply

  variables {
    lock = {
      kind = "CanNotDelete"
    }
  }

  assert {
    condition     = output.lock_azapi.body.properties.notes == null
    error_message = "An omitted top-level lock notes value should remain null."
  }
}

run "top_level_lock_with_notes" {
  command = apply

  variables {
    lock = {
      kind  = "ReadOnly"
      notes = "Managed by Terraform."
    }
  }

  assert {
    condition     = output.lock_azapi.body.properties.notes == "Managed by Terraform."
    error_message = "Top-level lock notes should pass through unchanged."
  }
}

run "private_endpoint_lock_without_notes" {
  command = apply

  variables {
    private_endpoints_scope = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sa"
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        lock = {
          kind = "CanNotDelete"
        }
      }
    }
  }

  assert {
    condition     = output.lock_private_endpoint_azapi["pe1"].body.properties.notes == null
    error_message = "An omitted private endpoint lock notes value should remain null."
  }
}

run "private_endpoint_lock_with_notes" {
  command = apply

  variables {
    role_assignment_definition_lookup_enabled = false
    private_endpoints_scope                   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sa"
    private_endpoints = {
      pe1 = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
        lock = {
          kind  = "ReadOnly"
          notes = "Managed by Terraform."
        }
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.4"
            member_name        = "blob"
          }
        }
        role_assignments = {
          reader = {
            name                       = "11111111-1111-1111-1111-111111111111"
            role_definition_id_or_name = "/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            principal_id               = "00000000-0000-0000-0000-000000000001"
          }
        }
      }
    }
  }

  assert {
    condition     = output.lock_private_endpoint_azapi["pe1"].body.properties.notes == "Managed by Terraform."
    error_message = "Private endpoint lock notes should pass through unchanged."
  }

  assert {
    condition     = output.private_endpoints_azapi["pe1"].body.properties.ipConfigurations[0].properties.memberName == "blob"
    error_message = "Private endpoint member_name should remain unchanged."
  }

  assert {
    condition     = output.role_assignments_private_endpoint_azapi["pe1-reader"].name == "11111111-1111-1111-1111-111111111111"
    error_message = "Private endpoint role assignment names should remain unchanged."
  }
}
