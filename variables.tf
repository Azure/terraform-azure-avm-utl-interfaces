variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "parent_id" {
  type        = string
  description = "The resource ID of the parent resource, this will typically be a resource group or management group scope."
  nullable    = false
}

variable "this_resource_id" {
  type        = string
  description = "The resource ID of this resource, this is used when deploying extension resources such as role assignments."
  nullable    = false
}

variable "location" {
  type        = string
  description = "The location for resources that require it."
  nullable    = true
  default     = null
}
