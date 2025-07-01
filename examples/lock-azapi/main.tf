data "azapi_client_config" "current" {}

resource "random_pet" "name" {
  length    = 2
  separator = "-"
}

resource "azapi_resource" "rg" {
  location  = "swedencentral"
  name      = "rg-${random_pet.name.id}"
  parent_id = data.azapi_client_config.current.subscription_resource_id
  type      = "Microsoft.Resources/resourceGroups@2024-03-01"
  retry = {
    error_message_regex  = ["ScopeLocked"]
    interval_seconds     = 15
    max_interval_seconds = 60
  }

  timeouts {
    delete = "5m"
  }
}

# In ordinary usage, the lock attribute value would be set to var.lock.
module "avm_interfaces" {
  source = "../../"

  lock = {
    kind = "CanNotDelete"
  }
}

resource "azapi_resource" "lock" {
  name      = module.avm_interfaces.lock_azapi.name != null ? module.avm_interfaces.lock_azapi.name : "lock-${azapi_resource.rg.name}"
  parent_id = azapi_resource.rg.id
  type      = module.avm_interfaces.lock_azapi.type
  body      = module.avm_interfaces.lock_azapi.body
}

# To avoid issues with the idempotency check, we add a sleep resource.
# This is not necessary in production code, but it helps to avoid issues in this example.
resource "time_sleep" "wait_for_lock" {
  create_duration = "20s"

  depends_on = [azapi_resource.lock]
}
