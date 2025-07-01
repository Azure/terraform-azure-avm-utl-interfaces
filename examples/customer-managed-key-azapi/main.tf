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
