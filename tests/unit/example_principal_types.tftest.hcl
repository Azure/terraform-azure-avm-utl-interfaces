mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      object_id                = "00000000-0000-0000-0000-000000000001"
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000000"
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/providers/Microsoft.Authorization/roleDefinitions/b7e6dc6d-f1e8-4753-8033-0f276bb0955b"
            role_name = "Storage Blob Data Owner"
          },
          {
            id        = "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
            role_name = "Contributor"
          },
        ]
      }
    }
  }

  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
      output = {
        id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test"
      }
    }
  }
}

mock_provider "random" {}

variables {
  enable_telemetry = false
}

run "role_assignment_example_infers_principal_type" {
  command = apply

  module {
    source = "./examples/role-assignments-azapi"
  }

  assert {
    condition     = azapi_resource.role_assignments["example"].body.properties.principalType == null
    error_message = "The role assignment example must let Azure infer the authenticated principal's type by default."
  }
}

run "role_assignment_example_accepts_user" {
  command = apply

  module {
    source = "./examples/role-assignments-azapi"
  }

  variables {
    user_principal_type = "User"
  }

  assert {
    condition     = azapi_resource.role_assignments["example"].body.properties.principalType == "User"
    error_message = "The role assignment example must preserve an explicit User principal type."
  }
}

run "role_assignment_example_accepts_service_principal" {
  command = apply

  module {
    source = "./examples/role-assignments-azapi"
  }

  variables {
    user_principal_type = "ServicePrincipal"
  }

  assert {
    condition     = azapi_resource.role_assignments["example"].body.properties.principalType == "ServicePrincipal"
    error_message = "The role assignment example must preserve an explicit ServicePrincipal principal type."
  }
}

run "named_role_assignment_example_infers_principal_type" {
  command = apply

  module {
    source = "./examples/role-assignments-azapi-name-override"
  }

  assert {
    condition     = azapi_resource.role_assignments["example"].body.properties.principalType == null
    error_message = "The named role assignment example must let Azure infer the authenticated principal's type by default."
  }
}

run "private_endpoint_example_infers_principal_type" {
  command = apply

  module {
    source = "./examples/private-endpoints-azapi"
  }

  assert {
    condition     = azapi_resource.private_endpoint_role_assignments["example-example"].body.properties.principalType == null
    error_message = "The private endpoint's named-role assignment must let Azure infer the authenticated principal's type by default."
  }

  assert {
    condition     = azapi_resource.private_endpoint_role_assignments["example-example2"].body.properties.principalType == null
    error_message = "The private endpoint's role-ID assignment must let Azure infer the authenticated principal's type by default."
  }
}
