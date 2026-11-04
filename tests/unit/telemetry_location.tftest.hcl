mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_id          = "00000000-0000-0000-0000-000000000000"
      tenant_id                = "00000000-0000-0000-0000-000000000000"
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {}

run "telemetry_disabled_without_location" {
  command = plan

  variables {
    enable_telemetry = false
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0 && length(terraform_data.telemetry) == 0
    error_message = "Disabling telemetry without a location should not create telemetry resources."
  }
}

run "telemetry_disabled_with_null_location" {
  command = plan

  variables {
    enable_telemetry = false
    location         = null
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 0 && length(terraform_data.telemetry) == 0
    error_message = "Disabling telemetry with a null location should not create telemetry resources."
  }
}

run "telemetry_enabled_without_location" {
  command = plan

  expect_failures = [
    var.location,
  ]
}

run "telemetry_enabled_with_null_location" {
  command = plan

  variables {
    location = null
  }

  expect_failures = [
    var.location,
  ]
}

run "telemetry_enabled_with_location" {
  command = plan

  variables {
    location = "eastus"
  }

  assert {
    condition     = length(azapi_resource.telemetry) == 1 && azapi_resource.telemetry[0].location == "eastus"
    error_message = "Enabled telemetry should use the supplied location."
  }
}
