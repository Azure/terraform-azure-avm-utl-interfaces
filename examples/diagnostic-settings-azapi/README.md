<!-- BEGIN_TF_DOCS -->
# diagnostic settings interface example

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

resource "azapi_resource" "law" {
  location  = azapi_resource.rg.location
  name      = "law-${random_pet.name.id}"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.OperationalInsights/workspaces@2023-09-01"
  body = {
    properties = {
      sku = {
        name = "PerGB2018"
      }
      retentionInDays = 30
      workspaceCapping = {
        dailyQuotaGb = 1
      }
    }
  }
}

resource "azapi_resource" "stg" {
  location  = azapi_resource.rg.location
  name      = "stg${replace(random_pet.name.id, "-", "")}"
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    kind = "StorageV2"
    properties = {
      accessTier                   = "Hot"
      allowBlobPublicAccess        = true
      allowCrossTenantReplication  = true
      allowSharedKeyAccess         = true
      defaultToOAuthAuthentication = false
      encryption = {
        keySource = "Microsoft.Storage"
        services = {
          queue = {
            keyType = "Service"
          }
          table = {
            keyType = "Service"
          }
        }
      }
      isHnsEnabled      = false
      isNfsV3Enabled    = false
      isSftpEnabled     = false
      minimumTlsVersion = "TLS1_2"
      networkAcls = {
        defaultAction = "Allow"
      }
      publicNetworkAccess      = "Enabled"
      supportsHttpsTrafficOnly = true
    }
    sku = {
      name = "Standard_ZRS"
    }
  }
}

# In ordinary usage, the diagnostic_settings attribute value would be set to var.diagnostic_settings.
# However, because we are creating the log analytics workspace in this example, we need to set the workspace_resource_id attribute value to the ID of the log analytics workspace.
module "avm_interfaces" {
  source = "../../"

  diagnostic_settings = {
    example = {
      name                           = "tolaw"
      metric_categories              = ["Capacity", "Transaction"]
      log_categories                 = []
      log_groups                     = []
      log_analytics_destination_type = "Dedicated"
      workspace_resource_id          = azapi_resource.law.id
    }
  }
}

resource "azapi_resource" "diag_settings" {
  for_each = module.avm_interfaces.diagnostic_settings_azapi

  name      = each.value.name
  parent_id = "${azapi_resource.stg.id}/blobServices/default"
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

- [azapi_resource.diag_settings](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.law](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
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