# terraform-azure-avm-utl-interfaces

This module helps AzAPI module authors satisfy the interface requirements of Azure Verified Modules.
It deploys no resources.
It translates data from the standard variable inputs and generates resource data for AzAPI resources!
Please see the examples for usage.

## Example usage

```hcl
module "avm_interfaces" {
  source              = "Azure/avm-utl-interfaces/azure"
  diagnostic_settings = var.diagnostic_settings
}

resource "azapi_resource" "diag_settings" {
  for_each = module.avm_interfaces.diagnostic_settings_azapi

  type      = each.value.type
  body      = each.value.body
  name      = each.value.name
  parent_id = azapi_resource.my_resource.parent_id
}
```

## Role assignments

This module will also translate role definition names into role definition resource ids.
You can control this with the `role_assignment_definition_lookup_enabled` variable.

If you want to use this feature you need to provide the base scope for the listing of the role definitions.
You do this by specifying the `role_assignment_definition_scope` variable.

## Private endpoints

This module will calculate names for resources if they are not supplied in the variable.
To ensure uniqueness, it will use the resource id of the parent resource.
Therefore you must supply this in the `private_endpoints_scope` variable.

Additionally, you cna control whether the module generates the private DNS zone group resources with the `private_endpoints_manage_dns_zone_group` variable.
If you are relying on Azure Policy to manage the DNS zone group, you should set this to false.
