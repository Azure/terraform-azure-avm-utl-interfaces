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

locals {
  subnet_resource_id = "${azapi_resource.vnet.output.id}/subnets/subnet"
}

# In ordinary usage, the private_endpoints attribute value would be set to var.private_endpoints.
# However, in this example, we are using a data source in the same module to retrieve the object id.
module "avm_interfaces" {
  source = "../../"

  parent_id        = azapi_resource.rg.id
  this_resource_id = azapi_resource.stg.id
  private_endpoints = {
    example = {
      subnet_resource_id            = local.subnet_resource_id
      private_dns_zone_resource_ids = [azapi_resource.private_dns_zone.id]
      subresource_name              = "vault"
      lock = {
        name = "lock-${random_pet.name.id}"
        kind = "CanNotDelete"
      }
      role_assignments = {
        example = {
          role_definition_id_or_name = "Contributor"
          principal_type             = var.user_principal_type
          principal_id               = data.azapi_client_config.current.object_id
          description                = "Test role assignments"
        }
        example2 = {
          role_definition_id_or_name = "/subscriptions/${data.azapi_client_config.current.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/4d97b98b-1d4f-4787-a291-c67834d212e7"
          principal_type             = var.user_principal_type
          principal_id               = data.azapi_client_config.current.object_id
          description                = "Test role assignments"
        }
      }
    }
  }
}

moved {
  from = azapi_resource.private_endpoints
  to   = module.avm_interfaces.azapi_resource.private_endpoints
}

moved {
  from = azapi_resource.private_endpoint_locks
  to   = module.avm_interfaces.azapi_resource.private_endpoint_locks
}

moved {
  from = azapi_resource.private_dns_zone_groups
  to   = module.avm_interfaces.azapi_resource.private_dns_zone_groups
}

moved {
  from = azapi_resource.private_endpoint_role_assignments
  to   = module.avm_interfaces.azapi_resource.private_endpoint_role_assignments
}

# resource "azapi_resource" "private_endpoints" {
#   for_each = module.avm_interfaces.private_endpoints_azapi

#   location  = azapi_resource.keyvault.location
#   name      = each.value.name
#   parent_id = azapi_resource.rg.id
#   type      = each.value.type
#   body      = each.value.body
#   retry = {
#     error_message_regex  = ["ScopeLocked"]
#     interval_seconds     = 15
#     max_interval_seconds = 60
#   }

#   timeouts {
#     delete = "5m"
#   }
# }

# resource "azapi_resource" "private_endpoint_locks" {
#   for_each = module.avm_interfaces.lock_private_endpoint_azapi

#   name      = each.value.name
#   parent_id = azapi_resource.private_endpoints[each.value.pe_key].id
#   type      = each.value.type
#   body      = each.value.body

#   depends_on = [
#     azapi_resource.private_dns_zone_groups,
#     azapi_resource.private_endpoint_role_assignments
#   ]
# }

# resource "azapi_resource" "private_dns_zone_groups" {
#   for_each = module.avm_interfaces.private_dns_zone_groups_azapi

#   name      = each.value.name
#   parent_id = azapi_resource.private_endpoints[each.key].id
#   type      = each.value.type
#   body      = each.value.body
#   retry = {
#     error_message_regex  = ["ScopeLocked"]
#     interval_seconds     = 15
#     max_interval_seconds = 60
#   }

#   timeouts {
#     delete = "5m"
#   }
# }

# resource "azapi_resource" "private_endpoint_role_assignments" {
#   for_each = module.avm_interfaces.role_assignments_private_endpoint_azapi

#   name      = each.value.name
#   parent_id = azapi_resource.private_endpoints[each.value.pe_key].id
#   type      = each.value.type
#   body      = each.value.body
#   retry = {
#     error_message_regex  = ["ScopeLocked"]
#     interval_seconds     = 15
#     max_interval_seconds = 60
#   }

#   timeouts {
#     delete = "5m"
#   }
# }
