data "azapi_client_config" "current" {}

resource "random_pet" "name" {
  length    = 2
  separator = "-"
}

resource "azapi_resource" "rg" {
  location = "australiaeast"
  name     = "rg-${random_pet.name.id}"
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
}

resource "azapi_resource" "private_dns_zone" {
  location  = "global"
  name      = "privatelink.vaultcore.azure.net"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Network/privateDnsZones@2024-06-01"
}

resource "azapi_resource" "vnet" {
  location  = azapi_resource.rg.location
  name      = "vnet-${random_pet.name.id}1"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Network/virtualNetworks@2024-05-01"
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
}

resource "azapi_resource" "keyvault" {
  location  = azapi_resource.rg.location
  name      = replace("kv${random_pet.name.id}2", "-", "")
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.KeyVault/vaults@2023-07-01"
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
}

resource "azapi_resource" "asg" {
  location  = azapi_resource.rg.location
  name      = "asg-${random_pet.name.id}"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Network/applicationSecurityGroups@2024-05-01"
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
      name                            = "pe-${azapi_resource.keyvault.name}"
      subnet_resource_id              = local.subnet_resource_id
      private_dns_zone_resource_ids   = [azapi_resource.private_dns_zone.id]
      subresource_name                = "vault"
      network_interface_name          = "nic-${azapi_resource.keyvault.name}"
      private_service_connection_name = "psc-${azapi_resource.keyvault.name}"
      application_security_group_associations = {
        asg = azapi_resource.asg.id
      }
      ip_configurations = {
        ipconfig1 = {
          name               = "ipconfig"
          private_ip_address = cidrhost(azapi_resource.vnet.output.properties.addressSpace.addressPrefixes[0], 4)
        }
      }
    }
  }
  private_endpoints_manage_dns_zone_group = false
  private_endpoints_scope                 = azapi_resource.keyvault.id
  role_assignment_definition_scope        = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
}



resource "azapi_resource" "private_endpoints" {
  for_each = module.avm_interfaces.private_endpoints_azapi

  location  = azapi_resource.keyvault.location
  name      = each.value.name
  parent_id = azapi_resource.rg.id
  type      = each.value.type
  body      = each.value.body
}
