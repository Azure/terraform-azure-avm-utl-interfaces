<!-- BEGIN_TF_DOCS -->
# role assignments interface example

```hcl
resource "random_pet" "name" {
  length    = 2
  separator = "-"
}

resource "azapi_resource" "rg" {
  location = "swedencentral"
  name     = "rg-${random_pet.name.id}"
  type     = "Microsoft.Resources/resourceGroups@2024-03-01"
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.6)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [azapi_resource.lock](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.rg](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
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