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

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.3.0"

  enable_telemetry = var.enable_telemetry
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

resource "azapi_resource" "rg" {
  location                  = module.regions.regions[random_integer.region_index.result].name
  name                      = module.naming.resource_group.name_unique
  type                      = "Microsoft.Resources/resourceGroups@2021-04-01"
  schema_validation_enabled = false
}

resource "azapi_resource" "umi" {
  location  = azapi_resource.rg.location
  name      = module.naming.user_assigned_identity.name_unique
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31"
  response_export_values = [
    "properties.clientId",
    "properties.principalId",
  ]
}

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
          role_definition_id_or_name = "Key Vault Crypto User"
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
      principal_type             = var.user_principal_type
    }
  }
}

module "avm_interfaces" {
  source = "../../"

  customer_managed_key_v2 = {
    key_vault_key_uri                = module.key_vault.keys_resource_ids["cmk"].versionless_id
    user_assigned_identity_client_id = azapi_resource.umi.output.properties.clientId
  }
}

resource "azapi_resource" "registry" {
  location  = azapi_resource.rg.location
  name      = module.naming.container_registry.name_unique
  parent_id = azapi_resource.rg.id
  type      = "Microsoft.ContainerRegistry/registries@2023-07-01"
  body = {
    properties = {
      adminUserEnabled = false
      encryption = {
        status = "enabled"
        keyVaultProperties = {
          identity      = module.avm_interfaces.customer_managed_key_azapi_v2.identity_client_id
          keyIdentifier = module.avm_interfaces.customer_managed_key_azapi_v2.versionless_key_uri
        }
      }
    }
    sku = {
      name = "Premium"
    }
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azapi_resource.umi.id]
  }
}
