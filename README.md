<!-- BEGIN_TF_DOCS -->
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

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.6)

## Resources

The following resources are used by this module:

- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.role_assignment_name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [random_uuid.role_assignment_name_private_endpoint](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azapi_client_config.telemetry](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)
- [azapi_resource.customer_managed_key_identity](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) (data source)
- [azapi_resource_list.role_definitions](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource_list) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key)

Description: An object containing the following attributes:

- `key_vault_resource_id` - The resource ID of the key vault.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not provided, the latest version will be used.
- `user_assigned_identity` - (Optional) An object containing the resource ID of the user assigned identity.
  - `resource_id` - The resource ID of the user assigned identity.

Type:

```hcl
object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
```

Default: `null`

### <a name="input_customer_managed_key_key_vault_domain"></a> [customer\_managed\_key\_key\_vault\_domain](#input\_customer\_managed\_key\_key\_vault\_domain)

Description: The domain name for the key vault. Default is `vault.azure.net`.

Type: `string`

Default: `"vault.azure.net"`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description:   A map of diagnostic settings to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
  - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
  - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_diagnostic_settings_v2"></a> [diagnostic\_settings\_v2](#input\_diagnostic\_settings\_v2)

Description:   A map of diagnostic settings to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  This is a preview of the new diagnostic settings interface, which fully supports all features of the Azure Diagnostic Settings API.

  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `logs` - (Optional) A set of log groups to send to the log analytics workspace.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
  - `metrics` - (Optional) A set of metric categories to send to the log analytics workspace.
  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.

Type:

```hcl
map(object({
    name = optional(string, null)
    logs = optional(set(object({
      category       = optional(string, null)
      category_group = optional(string, null)
      enabled        = optional(bool, true)
      retention_policy = optional(object({
        days    = optional(number, 0)
        enabled = optional(bool, false)
      }), {})
    })), [])
    metrics = optional(set(object({
      category = optional(string, null)
      enabled  = optional(bool, true)
      retention_policy = optional(object({
        days    = optional(number, 0)
        enabled = optional(bool, false)
      }), {})
    })), [])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_lock"></a> [lock](#input\_lock)

Description:   Controls the resource lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description:   Controls the managed identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints)

Description:   A map of private endpoints to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `role_assignments` - (Optional) This module does not do anything with this, it is used by the parent module to create role assignments.
    - `role_definition_id_or_name` - The ID or name of the role definition to assign.
    - `principal_id` - The ID of the principal to assign the role to.
    - `description` - (Optional) A description of the role assignment.
    - `skip_service_principal_aad_check` - (Optional) Whether to skip the AAD check for service principals.
    - `condition` - (Optional) The condition under which the role assignment is active.
    - `condition_version` - (Optional) The version of the condition.
    - `delegated_managed_identity_resource_id` - (Optional) The resource ID of the delegated managed identity to assign the role to.
    - `principal_type` - (Optional) The type of principal to assign the role to. Possible values are `\"User\"`, `\"Group\"`, `\"ServicePrincipal\"`, and `\"MSI\"`.
  - `lock` - (Optional) This module does not do anything with this, it is used by the parent module to create locks assignments.
    - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
    - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `subresource_name` - The name of the sub resource for the private endpoint.
  - `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
  - `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Key Vault.
  - `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
    - `name` - The name of the IP configuration.
    - `private_ip_address` - The private IP address of the IP configuration.

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = optional(string, null)
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_private_endpoints_manage_dns_zone_group"></a> [private\_endpoints\_manage\_dns\_zone\_group](#input\_private\_endpoints\_manage\_dns\_zone\_group)

Description: Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy.

Type: `bool`

Default: `true`

### <a name="input_private_endpoints_scope"></a> [private\_endpoints\_scope](#input\_private\_endpoints\_scope)

Description: This is typically the resource ID of the resource that the private endpoint is connected to.

Must be specified when `private_endpoints` are defined.

Type: `string`

Default: `null`

### <a name="input_role_assignment_definition_lookup_enabled"></a> [role\_assignment\_definition\_lookup\_enabled](#input\_role\_assignment\_definition\_lookup\_enabled)

Description: A control to disable the lookup of role definitions when creating role assignments.  
If you disable this then all role assignments must be supplied with a `role_definition_id_or_name` that is a valid role definition ID.

Type: `bool`

Default: `true`

### <a name="input_role_assignment_definition_scope"></a> [role\_assignment\_definition\_scope](#input\_role\_assignment\_definition\_scope)

Description: The scope at which the role assignments should be created. Used to look up role definitions by role name.

Must be specified when `role_assignments` are defined.

Type: `string`

Default: `null`

### <a name="input_role_assignment_name_use_random_uuid"></a> [role\_assignment\_name\_use\_random\_uuid](#input\_role\_assignment\_name\_use\_random\_uuid)

Description: A control to use a random UUID for the role assignment name.  
If set to false, the name will be a deterministic UUID based on the principal ID and role definition resource ID,  
though this can cause issues with duplicate UUIDs as the scope of the role assignment is not taken into account.

This is default to false to preserve existing behaviour.  
However, we recommend this is set to true to avoid resources becoming re-created due to computed attribute changes in the resource graph.

When this is set to true, you must not change the principal or role definition values in the `role_assignments` map after the initial creation of the role assignments as this will cause errors.  
Instead, use a new key in the map with the new values and remove the old entry.

Type: `bool`

Default: `false`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description:   A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.  
  Do not change principal or role definition values in this map after the initial creation of the role assignments as this will cause errors.  
  Instead, add a new entry to the map with a new key and remove the old entry.

  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - (Optional) No effect when using AzAPI.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_customer_managed_key_azapi"></a> [customer\_managed\_key\_azapi](#output\_customer\_managed\_key\_azapi)

Description: An object containing the following attributes:

- `identity_client_id` - The client ID of the user-assigned identity. Will be null if no user-assigned identity is provided.
- `identity_principal_id` - The principal ID of the user-assigned identity. Will be null if no user-assigned identity is provided.
- `identity_tenant_id` - The tenant ID of the user-assigned identity. Will be null if no user-assigned identity is provided.
- `key_name` - The name of the key. Will be null if no key is provided.
- `key_resource_id` - The resource ID of the key, including the version. If the key version is not provided, this will be null.
- `key_uri` - The URI of the key, including the version. If the key version is not provided, this will be null.
- `key_vault_uri` - The URI of the key vault.
- `key_version` - The version of the key. Will be null if no key is provided.
- `versionless_key_resource_id` - The resource ID of the key, without the version.
- `versionless_key_uri` - The URI of the key, without the version.

### <a name="output_diagnostic_settings_azapi"></a> [diagnostic\_settings\_azapi](#output\_diagnostic\_settings\_azapi)

Description: A map of diagnostic settings for use in azapi\_resource, the value is an object containing the following attributes:

- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.

### <a name="output_diagnostic_settings_azapi_v2"></a> [diagnostic\_settings\_azapi\_v2](#output\_diagnostic\_settings\_azapi\_v2)

Description: A map of diagnostic settings for use in azapi\_resource, the value is an object containing the following attributes:

- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.

### <a name="output_lock_azapi"></a> [lock\_azapi](#output\_lock\_azapi)

Description: An object for use in azapi\_resource with the following attributes:

- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.

### <a name="output_lock_private_endpoint_azapi"></a> [lock\_private\_endpoint\_azapi](#output\_lock\_private\_endpoint\_azapi)

Description: A flattened map of objects containing for use in azapi\_resource with the following attributes:

- `pe_key` - The key of the private endpoint, used to look up the parent id.
- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.

These locks should be used for private endpoints defined in var.private\_endpoints.

### <a name="output_managed_identities_azapi"></a> [managed\_identities\_azapi](#output\_managed\_identities\_azapi)

Description: The Managed Identity configuration for the azapi\_resource.  
Value is an object with the following attributes:

- `type` - The type of Managed Identity. Possible values are `SystemAssigned`, `UserAssigned`, or `SystemAssigned, UserAssigned`.
- `identity_ids` - A list of User Assigned Managed Identity resource IDs assigned to this resource.

### <a name="output_private_dns_zone_groups_azapi"></a> [private\_dns\_zone\_groups\_azapi](#output\_private\_dns\_zone\_groups\_azapi)

Description: A map of private DNS zone groups for use with azapi\_resource, the value is an object containing the following attributes:

- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.

### <a name="output_private_endpoints_azapi"></a> [private\_endpoints\_azapi](#output\_private\_endpoints\_azapi)

Description: A map of private endpoints for use with azapi\_resource, the value is an object containing the following attributes:

- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.
- `tags` - The tags of the resource.

### <a name="output_role_assignments_azapi"></a> [role\_assignments\_azapi](#output\_role\_assignments\_azapi)

Description: A map of role assignments for use in azapi\_resource, the value is an object containing the following attributes:

- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.

### <a name="output_role_assignments_private_endpoint_azapi"></a> [role\_assignments\_private\_endpoint\_azapi](#output\_role\_assignments\_private\_endpoint\_azapi)

Description: A flattened map of role assignments for private endpoints, the value is an object containing the following attributes:

- `pe_key` - The key of the private endpoint, used to look up the parent id.
- `assignment_key` - The key of the role assignment from the private endpoint object map.
- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.

These role assignments should be used for private endpoints defined in var.private\_endpoints.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->