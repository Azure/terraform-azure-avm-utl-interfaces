<!-- BEGIN_TF_DOCS -->
# customer managed key example

```hcl
terraform {
  required_version = "~> 1.9"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}
data "azapi_client_config" "current" {}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.3.0"

  enable_telemetry = var.enable_telemetry
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4.2"
}

# This is required for resource modules
resource "azapi_resource" "rg" {
  location                  = module.regions.regions[random_integer.region_index.result].name
  name                      = module.naming.resource_group.name_unique
  type                      = "Microsoft.Resources/resourceGroups@2021-04-01"
  schema_validation_enabled = false
}

# user-assigned managed identity
resource "azapi_resource" "umi" {
  location  = azapi_resource.rg.location
  name      = module.naming.user_assigned_identity.name_unique
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30"
  response_export_values = [
    "properties.principalId",
    "properties.clientId",
  ]
  schema_validation_enabled = false
}

# key vault & key
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  location            = azapi_resource.rg.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azapi_resource.rg.name
  tenant_id           = data.azapi_client_config.current.tenant_id
  keys = {
    cmk = {
      name     = "cmk"
      key_type = "RSA"
      key_size = 4096
      key_opts = ["wrapKey", "unwrapKey", "sign", "verify", "encrypt", "decrypt"]
      enabled  = true
      role_assignments = {
        umi = {
          principal_id               = azapi_resource.umi.output.properties.principalId
          role_definition_id_or_name = "Key Vault Crypto Service Encryption User"
          principal_type             = "ServicePrincipal"
        }
      }
    }
  }
  network_acls = {
    default_action = "Allow"
  }
  role_assignments = {
    admin = {
      principal_id               = data.azapi_client_config.current.object_id
      role_definition_id_or_name = "Key Vault Administrator"
      principal_type             = "User"
    }
  }
}

# In ordinary usage, the private_endpoints attribute value would be set to var.private_endpoints.
# However, in this example, we are using a data source in the same module to retrieve the object id.
module "avm_interfaces" {
  source = "../../"

  customer_managed_key = {
    key_name              = "cmk"
    key_vault_resource_id = module.key_vault.resource_id
    user_assigned_identity = {
      resource_id = azapi_resource.umi.id
    }
  }
  managed_identities = {
    system_assigned = false
    user_assigned_resource_ids = [
      azapi_resource.umi.id
    ]
  }
}

resource "azapi_resource" "storage" {
  location  = azapi_resource.rg.location
  name      = module.naming.storage_account.name_unique
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.Storage/storageAccounts@2023-05-01"
  body = {
    kind = "StorageV2"
    properties = {
      accessTier                   = "Hot"
      defaultToOAuthAuthentication = true
      encryption = {
        identity = {
          userAssignedIdentity = azapi_resource.umi.id
        }
        keyvaultproperties = {
          keyname     = module.avm_interfaces.customer_managed_key_azapi.key_name
          keyvaulturi = module.avm_interfaces.customer_managed_key_azapi.key_vault_uri
          keyversion  = null
        }
        keySource = "Microsoft.Keyvault"
      }
      minimumTlsVersion        = "TLS1_2"
      supportsHttpsTrafficOnly = true
    }
    sku = {
      name = "Standard_ZRS"
    }
  }

  identity {
    type         = module.avm_interfaces.managed_identities_azapi.type
    identity_ids = module.avm_interfaces.managed_identities_azapi.identity_ids
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azapi_resource.rg](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.storage](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.umi](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: Enable telemetry for the module

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_avm_interfaces"></a> [avm\_interfaces](#module\_avm\_interfaces)

Source: ../../

Version:

### <a name="module_key_vault"></a> [key\_vault](#module\_key\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: 0.10.0

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.4.2

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/avm-utl-regions/azurerm

Version: 0.3.0

<!-- END_TF_DOCS -->