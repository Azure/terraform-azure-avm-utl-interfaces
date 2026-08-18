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

run "versionless_key_vault_uri" {
  command = apply

  variables {
    customer_managed_key_v2 = {
      key_vault_key_uri = "https://example.vault.azure.net/keys/cmk"
      user_assigned_identity = {
        client_id = "11111111-1111-1111-1111-111111111111"
      }
    }
  }

  assert {
    condition     = output.customer_managed_key_azapi_v2.key_vault_uri == "https://example.vault.azure.net"
    error_message = "The Key Vault URI should contain only the scheme and host."
  }

  assert {
    condition     = output.customer_managed_key_azapi_v2.key_name == "cmk"
    error_message = "The key name should be decomposed from the key URI."
  }

  assert {
    condition     = output.customer_managed_key_azapi_v2.key_version == null && output.customer_managed_key_azapi_v2.key_uri == null
    error_message = "A versionless key URI should produce null versioned values."
  }

  assert {
    condition     = output.customer_managed_key_azapi_v2.versionless_key_uri == "https://example.vault.azure.net/keys/cmk"
    error_message = "The versionless key URI should be preserved."
  }

  assert {
    condition     = output.customer_managed_key_azapi_v2.identity_client_id == "11111111-1111-1111-1111-111111111111"
    error_message = "The identity client ID should pass through unchanged."
  }
}

run "versioned_key_vault_uri" {
  command = apply

  variables {
    customer_managed_key_v2 = {
      key_vault_key_uri = "https://example.vault.azure.net/keys/cmk/0123456789abcdef"
    }
  }

  assert {
    condition     = output.customer_managed_key_azapi_v2.key_version == "0123456789abcdef"
    error_message = "The key version should be decomposed from the key URI."
  }

  assert {
    condition     = output.customer_managed_key_azapi_v2.key_uri == "https://example.vault.azure.net/keys/cmk/0123456789abcdef"
    error_message = "A versioned key URI should be exposed as key_uri."
  }

  assert {
    condition     = output.customer_managed_key_azapi_v2.versionless_key_uri == "https://example.vault.azure.net/keys/cmk"
    error_message = "The trailing key version should be removed from versionless_key_uri."
  }
}

run "managed_hsm_uri" {
  command = apply

  variables {
    customer_managed_key_v2 = {
      key_vault_key_uri = "https://example.managedhsm.azure.net/keys/cmk/version"
    }
  }

  assert {
    condition     = output.customer_managed_key_azapi_v2.key_vault_uri == "https://example.managedhsm.azure.net"
    error_message = "Managed HSM hosts should be preserved without DNS suffix derivation."
  }
}

run "sovereign_cloud_uri" {
  command = apply

  variables {
    customer_managed_key_v2 = {
      key_vault_key_uri = "https://example.vault.usgovcloudapi.net/keys/cmk"
    }
  }

  assert {
    condition     = output.customer_managed_key_azapi_v2.key_vault_uri == "https://example.vault.usgovcloudapi.net"
    error_message = "Sovereign cloud hosts should be preserved without DNS suffix derivation."
  }

  assert {
    condition = (
      output.customer_managed_key_azapi_v2.key_resource_id == null
      && output.customer_managed_key_azapi_v2.versionless_key_resource_id == null
      && output.customer_managed_key_azapi_v2.identity_principal_id == null
      && output.customer_managed_key_azapi_v2.identity_tenant_id == null
    )
    error_message = "Values that require ARM resource IDs should always be null."
  }
}
