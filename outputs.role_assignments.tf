output "role_assignments_azapi" {
  value       = local.role_assignments_azapi
  description = <<DESCRIPTION
A map of role assignments for use in azapi_resource, the value is an object containing the following attributes:

- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.
DESCRIPTION
}
