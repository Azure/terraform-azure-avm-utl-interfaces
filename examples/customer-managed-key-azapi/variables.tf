variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable telemetry for the module"
}

variable "user_principal_type" {
  type        = string
  default     = null
  description = "The authenticated principal's type for role assignments. Set to User or ServicePrincipal to override; null lets Azure determine the type."
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure region for this module's resources or telemetry deployment."
  nullable    = false
}
