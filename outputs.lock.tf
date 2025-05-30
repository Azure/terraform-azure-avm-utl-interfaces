output "lock_azapi" {
  description = <<DESCRIPTION
An object for use in azapi_resource with the following attributes:

- `type` - The type of the resource.
- `name` - The name of the resource.
- `body` - The body of the resource.
DESCRIPTION
  value       = local.lock_azapi
}
