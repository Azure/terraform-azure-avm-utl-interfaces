data "azapi_client_config" "current" {}

resource "random_pet" "name" {
  length    = 2
  separator = "-"
}

resource "azapi_resource" "rg" {
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
  location = "australiaeast"
  name     = "rg-${random_pet.name.id}"
}

resource "azapi_resource" "private_dns_zone" {
  type      = "Microsoft.Network/privateDnsZones@2024-06-01"
  location  = "global"
  name      = "privatelink.vaultcore.azure.net"
  parent_id = azapi_resource.rg.id
}

resource "azapi_resource" "vnet" {
  type = "Microsoft.Network/virtualNetworks@2024-05-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = ["10.0.0.0/16"]
      }
      subnets = [
        {
          name = "subnet"
          properties = {
            addressPrefix = "10.0.0.0/24"
          }
        }
      ]
    }
  }
  location  = azapi_resource.rg.location
  name      = "vnet-${random_pet.name.id}1"
  parent_id = azapi_resource.rg.id
}

resource "azapi_resource" "keyvault" {
  type = "Microsoft.KeyVault/vaults@2023-07-01"
  body = {
    properties = {
      sku = {
        family = "A"
        name   = "standard"
      }
      tenantId       = data.azapi_client_config.current.tenant_id
      accessPolicies = []
    }
  }
  location  = azapi_resource.rg.location
  name      = replace("kv${random_pet.name.id}2", "-", "")
  parent_id = azapi_resource.rg.id
}

locals {
  subnet_resource_id = "${azapi_resource.vnet.output.id}/subnets/subnet"
}

# In ordinary usage, the private_endpoints attribute value would be set to var.private_endpoints.
# However, in this example, we are using a data source in the same module to retrieve the object id.
module "avm_interfaces" {
  source = "../../"
  private_endpoints = {
    example = {
      subnet_resource_id            = local.subnet_resource_id
      private_dns_zone_resource_ids = [azapi_resource.private_dns_zone.id]
      subresource_name              = "vault"
    }
  }
  private_endpoints_scope          = azapi_resource.keyvault.id
  role_assignment_definition_scope = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
}

output "private_endpoints_azapi" {
  value = module.avm_interfaces.private_endpoints_azapi
}

output "private_dns_zone_groups_azapi" {
  value = module.avm_interfaces.private_dns_zone_groups_azapi
}

resource "azapi_resource" "private_endpoints" {
  for_each = module.avm_interfaces.private_endpoints_azapi

  type      = each.value.type
  body      = each.value.body
  location  = azapi_resource.keyvault.location
  name      = each.value.name
  parent_id = azapi_resource.rg.id
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = module.avm_interfaces.private_dns_zone_groups_azapi

  type      = each.value.type
  body      = each.value.body
  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.key].id
}
