<!-- BEGIN_TF_DOCS -->
# managed identity interface example

```hcl
resource "random_pet" "name" {
  length    = 2
  separator = ""
}

resource "azapi_resource" "rg" {
  location = "australiaeast"
  name     = "rg-${random_pet.name.id}"
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
}

resource "azapi_resource" "stg" {
  location  = azapi_resource.rg.location
  name      = "stg${random_pet.name.id}1"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    sku = {
      name = "Standard_ZRS"
    }
    kind = "StorageV2"
  }

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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [azapi_resource.rg](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.stg](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [random_pet.name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_avm_interfaces"></a> [avm\_interfaces](#module\_avm\_interfaces)

Source: ../../

Version:

<!-- END_TF_DOCS -->