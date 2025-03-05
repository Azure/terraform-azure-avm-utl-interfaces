variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default = null
}

variable "customer_managed_key_key_vault_domain" {
  type        = string
  default     = "vault.azure.net"
  nullable    = false
  description = "The domain name for the key vault. Default is `vault.azure.net`."
}
