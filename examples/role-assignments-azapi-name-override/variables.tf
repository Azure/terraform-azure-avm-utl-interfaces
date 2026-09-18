variable "user_principal_type" {
  type        = string
  default     = "User"
  description = "This is so we can set the correct value in the CI/CD pipeline. In a real-world scenario, this would be set to 'User' or 'ServicePrincipal' based on the principal type you are assigning the role to."
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}
