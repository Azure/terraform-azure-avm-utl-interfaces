variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable telemetry for the module."
}

variable "user_principal_type" {
  type        = string
  default     = "User"
  description = "The principal type used for the example's Key Vault administrator role assignment."
}
