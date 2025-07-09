<!-- BEGIN_TF_DOCS -->
# private endpoints interface example

```hcl
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
  private_endpoints_scope              = azapi_resource.keyvault.id
  role_assignment_definition_scope     = "/subscriptions/${data.azapi_client_config.current.subscription_id}"
  role_assignment_name_use_random_uuid = true
}



resource "azapi_resource" "private_endpoints" {
  for_each = module.avm_interfaces.private_endpoints_azapi

  location  = azapi_resource.keyvault.location
  name      = each.value.name
  parent_id = azapi_resource.rg.id
  type      = each.value.type
  body      = each.value.body
  retry = {
    error_message_regex  = ["ScopeLocked"]
    interval_seconds     = 15
    max_interval_seconds = 60
  }

  timeouts {
    delete = "5m"
  }
}

resource "azapi_resource" "private_endpoint_locks" {
  for_each = module.avm_interfaces.lock_private_endpoint_azapi

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.value.pe_key].id
  type      = each.value.type
  body      = each.value.body

  depends_on = [
    azapi_resource.private_dns_zone_groups,
    azapi_resource.private_endpoint_role_assignments
  ]
}

resource "azapi_resource" "private_dns_zone_groups" {
  for_each = module.avm_interfaces.private_dns_zone_groups_azapi

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.key].id
  type      = each.value.type
  body      = each.value.body
  retry = {
    error_message_regex  = ["ScopeLocked"]
    interval_seconds     = 15
    max_interval_seconds = 60
  }

  timeouts {
    delete = "5m"
  }
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = module.avm_interfaces.role_assignments_private_endpoint_azapi

  name      = each.value.name
  parent_id = azapi_resource.private_endpoints[each.value.pe_key].id
  type      = each.value.type
  body      = each.value.body
  retry = {
    error_message_regex  = ["ScopeLocked"]
    interval_seconds     = 15
    max_interval_seconds = 60
  }

  timeouts {
    delete = "5m"
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [azapi_resource.keyvault](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.private_dns_zone](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.private_dns_zone_groups](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.private_endpoint_locks](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.private_endpoint_role_assignments](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.private_endpoints](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.rg](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.vnet](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [random_pet.name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) (resource)
- [azapi_client_config.current](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_user_principal_type"></a> [user\_principal\_type](#input\_user\_principal\_type)

Description: This is so we can set the correct value in the CI/CD pipeline. In a real-world scenario, this would be set to 'User' or 'ServicePrincipal' based on the principal type you are assigning the role to.

Type: `string`

Default: `"User"`

## Outputs

The following outputs are exported:

### <a name="output_private_dns_zone_groups_azapi"></a> [private\_dns\_zone\_groups\_azapi](#output\_private\_dns\_zone\_groups\_azapi)

Description: n/a

### <a name="output_private_endpoints_azapi"></a> [private\_endpoints\_azapi](#output\_private\_endpoints\_azapi)

Description: n/a

## Modules

The following Modules are called:

### <a name="module_avm_interfaces"></a> [avm\_interfaces](#module\_avm\_interfaces)

Source: ../../

Version:

<!-- END_TF_DOCS -->