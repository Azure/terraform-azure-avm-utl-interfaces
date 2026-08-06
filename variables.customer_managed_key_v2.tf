variable "customer_managed_key_v2" {
  type = object({
    key_vault_key_uri                = string
    user_assigned_identity_client_id = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
An object containing the following attributes:

- `key_vault_key_uri` - The full Key Vault or Managed HSM key URI, with an optional trailing key version.
- `user_assigned_identity_client_id` - (Optional) The client ID of the user-assigned identity used to access the key.
DESCRIPTION

  validation {
    condition     = var.customer_managed_key_v2 == null || can(regex("^https://[^/]+/keys/[^/]+(/[^/]+)?$", var.customer_managed_key_v2.key_vault_key_uri))
    error_message = "`customer_managed_key_v2.key_vault_key_uri` must be a Key Vault or Managed HSM key URI, in the form `https://{vaultHost}/keys/{keyName}` or `https://{vaultHost}/keys/{keyName}/{keyVersion}`."
  }
  validation {
    condition     = try(var.customer_managed_key_v2.user_assigned_identity_client_id, null) == null || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.customer_managed_key_v2.user_assigned_identity_client_id))
    error_message = "`customer_managed_key_v2.user_assigned_identity_client_id` must be a valid GUID."
  }
}
