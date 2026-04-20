variable "role_assignment_definition_lookup_use_live_data" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
A control to disable the live lookup of role definitions when creating role assignments.
If you disable this then cached data will be used instead, which is more stable. The role definition data does not change often so this is a reasonable approach.
DESCRIPTION
}

variable "role_assignment_replace_on_immutable_value_changes" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
Whether to replace role assignments when the immutable values (principal ID or role definition ID) change.
This is disabled by default as any unknown values in these fields will cause the role assignment to be replaced on every apply.
If you are using known values for these fields then you can enable this to ensure that changes to the principal or role definition are applied.

Alternatively, remove the role assignment map entry and add a new one with a new key to achieve the same effect.
DESCRIPTION
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    name                                   = optional(string, null)
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of role assignments to create. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  Do not change principal or role definition values in this map after the initial creation of the role assignments as this will cause errors.
  Instead, add a new entry to the map with a new key and remove the old entry.

  - `role_assignment_name` - (Optional) The name of the role assignment. Must be a UUID. If not specified, a random UUID will be generated. Changing this forces the creation of a new resource.
  - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
  - `principal_id` - The ID of the principal to assign the role to.
  - `description` - (Optional) The description of the role assignment.
  - `skip_service_principal_aad_check` - DEPRECATED - (Optional) No effect when using AzAPI.
  - `condition` - (Optional) The condition which will be used to scope the role assignment.
  - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
  - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
  - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
DESCRIPTION
  nullable    = false

  validation {
    error_message = "principal_type must be one of 'User', 'Group', or 'ServicePrincipal'"
    condition = alltrue([
      for _, v in var.role_assignments : (
        v.principal_type == null ||
        contains(["User", "Group", "ServicePrincipal", "MSI"], v.principal_type)
      )
    ])
  }
  validation {
    error_message = "principal_id must be a UUID"
    condition = alltrue([
      for _, v in var.role_assignments : (
        can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", v.principal_id))
      )
    ])
  }
  validation {
    error_message = "condition_version must be '2.0' if condition is set"
    condition = alltrue([
      for _, v in var.role_assignments : (
        v.condition == null || (v.condition_version == "2.0")
      )
    ])
  }
}
