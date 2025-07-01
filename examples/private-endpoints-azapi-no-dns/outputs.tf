# this should be empty as private_endpoints_manage_dns_zone_group is false
output "private_dns_zone_groups_azapi" {
  value = module.avm_interfaces.private_dns_zone_groups_azapi
}

output "private_endpoints_azapi" {
  value = module.avm_interfaces.private_endpoints_azapi
}
