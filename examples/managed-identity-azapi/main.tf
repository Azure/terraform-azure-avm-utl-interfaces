data "azapi_client_config" "current" {}

resource "random_pet" "name" {
  length    = 2
  separator = ""
}

resource "azapi_resource" "rg" {
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
  location = "australiaeast"
  name     = "rg-${random_pet.name.id}"
}

resource "azapi_resource" "stg" {
  type = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    sku = {
      name = "Standard_LRS"
    }
    kind = "StorageV2"
  }
  location  = azapi_resource.rg.location
  name      = "stg${random_pet.name.id}1"
  parent_id = azapi_resource.rg.id

  identity {
    type         = module.avm_interfaces.managed_identities_azapi.type
    identity_ids = module.avm_interfaces.managed_identities_azapi.identity_ids
  }
}

# In ordinary usage, the private_endpoints attribute value would be set to var.managed_identities.
# However, in this example, we are using a data source in the same module to retrieve the object id.
module "avm_interfaces" {
  source = "../../"
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = []
  }
}
