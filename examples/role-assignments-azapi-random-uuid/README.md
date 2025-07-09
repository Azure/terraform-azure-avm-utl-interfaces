<!-- BEGIN_TF_DOCS -->
# role assignments interface example

This example uses random\_uuid to generate unique role assignment names.
This is useful when the deterministic is generated using unknown values and could cause needless re-creation of the role assignment.

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

# In ordinary usage, the role_assignments attribute value would be set to var.role_assignments.
# However, in this example, we are using a data source in the same module to retrieve the object id.
module "avm_interfaces" {
  source = "../../"

  role_assignment_definition_scope     = azapi_resource.rg.id
  role_assignment_name_use_random_uuid = true
  role_assignments = {
    example = {
      principal_id               = data.azapi_client_config.current.object_id
      role_definition_id_or_name = "Storage Blob Data Owner"
      principal_type             = var.user_principal_type
    }
  }
}

data "azapi_client_config" "current" {}

resource "azapi_resource" "role_assignments" {
  for_each = module.avm_interfaces.role_assignments_azapi

  name      = each.value.name
  parent_id = azapi_resource.rg.id
  type      = each.value.type
  body      = each.value.body
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

- [azapi_resource.rg](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.role_assignments](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
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

No outputs.

## Modules

The following Modules are called:

### <a name="module_avm_interfaces"></a> [avm\_interfaces](#module\_avm\_interfaces)

Source: ../../

Version:

<!-- END_TF_DOCS -->
