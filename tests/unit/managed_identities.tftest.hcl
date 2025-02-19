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

run "no_input" {
  command = apply

  assert {
    error_message = "Managed identity output should be null."
    condition     = output.managed_identities_azapi == null
  }
}

run "system_assigned" {
  command = apply

  variables {
    managed_identities = {
      system_assigned = true
    }
  }

  assert {
    error_message = "Managed identity type should be SystemAssigned."
    condition     = output.managed_identities_azapi.type == "SystemAssigned"
  }

  assert {
    error_message = "Managed identity user assigned identity ids should be empty."
    condition     = length(output.managed_identities_azapi.identity_ids) == 0
  }
}

run "user_assigned" {
  command = apply

  variables {
    managed_identities = {
      user_assigned_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ua1",
      ]
    }
  }

  assert {
    error_message = "Managed identity type should be UserAssigned."
    condition     = output.managed_identities_azapi.type == "UserAssigned"
  }

  assert {
    error_message = "Managed identity user assigned identity ids should match."
    condition = output.managed_identities_azapi.identity_ids == toset([
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ua1",
    ])
  }
}

run "system_user_assigned" {
  command = apply

  variables {
    managed_identities = {
      user_assigned_resource_ids = [
        "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ua1",
      ]
    }
  }
}
