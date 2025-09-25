# Bear with this because it get's a bit gnarly...
#
# The diagnostic settings API uses lists of objects for logs and metrics.
# This would be ok, but for the fact that some services add entries automatically.
# Often these are disabled, but they are still there.
# This means that if you try to manage diagnostic settings with a list of objects,
# you will end up in a situation where Terraform wants to remove the entries added
# by the service, and then the service adds them back again.
# This results in a non-idempotent configuration.
#
# The approach that I have developed here is to:
# 1. Use azapi_resource to create the diagnostic settings resource with the
#    user-supplied configuration - crucially we any ignore changes to the logs and metrics.
# 2. Use azapi_resource data source to read the existing configuration,
#    including any entries added by the service.
# 3. Combine the user-supplied configuration with the existing configuration
#    to produce a final configuration that includes both.
#    This is further complicated as we cannot just use distinct() on the list
#    of objects because the list is keyed by the categoryGroup or category property.
#    So, we have to convert the lists to maps keyed by these properties,
#    combine the maps, and then convert back to a list.
# 4. Finally, use azapi_update_resource to update the diagnostic settings resource
#    with the final configuration.
#
# Fun, heh?

# Let's first create the diagnostic settings resources.
# We will set lifecycle.ignore_changes to ignore changes to the logs and metrics.
# This means that if the service adds entries, Terraform will not try to remove them.
resource "azapi_resource" "diagnostic_settings" {
  for_each = local.diagnostic_settings_azapi

  name                 = each.value.name
  parent_id            = var.this_resource_id
  type                 = local.diagnostic_settings_type
  body                 = each.value.body
  create_headers       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_null_property = true
  read_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers       = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    ignore_changes = [body.properties.logs, body.properties.metrics]
  }
}

# Now we need to read the existing configuration using the azapi_resource data source.
# This happens after the azapi_resource creation above, due to the for_each value being
# the azapi_resource above.
# I explicitly export the metrics and logs values from the data source
data "azapi_resource" "diagnostic_settings" {
  for_each = azapi_resource.diagnostic_settings

  resource_id = each.value.id
  type        = each.value.type
  response_export_values = {
    metrics = "properties.metrics"
    logs    = "properties.logs"
  }
}

# Now the "fun" bit...
# Let's deal with logs first.
# These are keyed either with categoryGroup or category.
# We need to handle both cases.
# All of the below must be wrapped in a map, as there can be multiple diagnostic settings resources
# in var.diagnostic_settings.

# For each diagnostic settings supplied, let's read in the log settings that are categoryGroup based...
# I turn this into a map keyed by categoryGroup for easier merging later.
# Note the condition to exclude null categoryGroup values (those would be the category based ones).
locals {
  logs_existing_category_groups = {
    for k, v in data.azapi_resource.diagnostic_settings : k => {
      for log in coalescelist(v.output.logs, []) : log.categoryGroup => log if log.categoryGroup != null
    }
  }
}

# Now for the user supplied configuration, we loop through var.diagnostic_settings.
# Again, we turn this into a map keyed by categoryGroup for easier merging later.
locals {
  logs_supplied_category_groups = {
    for k, v in var.diagnostic_settings : k => {
      for log in coalescelist(local.logs_final_supplied[k], []) : log.categoryGroup => log if log.categoryGroup != null
    }
  }
}

# Now we can combine the two maps, preferring the user supplied configuration.
# This is done by looping through the distinct keys of both maps,
# and using try() to get the user supplied value of that key if it exists,
# otherwise falling back to the existing value of the same key. One of these will always exist.
# Finally, we convert the map back to a list by accessing the values of the map.
locals {
  logs_combined_category_groups = {
    for k, v in var.diagnostic_settings : k => [
      for k2 in distinct(
        concat(
          keys(local.logs_existing_category_groups[k]),
          keys(local.logs_supplied_category_groups[k])
        )
      ) : try(local.logs_supplied_category_groups[k][k2], local.logs_existing_category_groups[k][k2])
    ]
  }
}

# Now we do the same for category based logs.
# Note that we have to do this separately because the keys are different.
# We cannot just combine everything into one map because the keys may clash.
locals {
  logs_existing_categories = {
    for k, v in data.azapi_resource.diagnostic_settings : k => length(v.output.logs) > 0 ? {
      for log in v.output.logs : log.category => log if log.category != null
    } : {}
  }
  logs_supplied_categories = {
    for k, v in var.diagnostic_settings : k => length(v.logs) > 0 ? {
      for log in local.logs_final_supplied[k] : log.category => log if log.category != null
    } : {}
  }
}

# Merging the above together...
locals {
  logs_combined_categories = {
    for k, v in var.diagnostic_settings : k => [
      for k2 in distinct(
        concat(
          keys(local.logs_existing_categories[k]),
          keys(local.logs_supplied_categories[k])
        )
      ) : try(local.logs_supplied_categories[k][k2], local.logs_existing_categories[k][k2])
    ]
  }
}

# Finally, we merge the two combined log category and categoryGroup lists into one final list of logs.
# The distinct() function here is probably not strictly necessary,
# but it doesn't hurt to ensure there are no duplicates.
locals {
  logs_combined_all = {
    for k, v in data.azapi_resource.diagnostic_settings : k => distinct(
      concat(
        local.logs_combined_category_groups[k],
        local.logs_combined_categories[k]
      )
    )
  }
}

# Still here? Now let's do the same for metrics.
# Metrics are simpler as they are only keyed by category.
# So we just need to create the existing and supplied maps,
# combine them, and convert back to a list.

# First, we read in the existing metrics from the data source.
# We turn this into a map keyed by category for easier merging later.
locals {
  metrics_existing = {
    for k, v in data.azapi_resource.diagnostic_settings : k => length(v.output.metrics) > 0 ? {
      for metric in v.output.metrics : metric.category => metric
    } : {}
  }
}

# Now for the user supplied configuration, we loop through var.diagnostic_settings.
# Again, we turn this into a map keyed by category for easier merging later.
locals {
  metrics_supplied = {
    for k, v in var.diagnostic_settings : k => length(v.metrics) > 0 ? {
      for metric in local.metrics_final_supplied[k] : metric.category => metric
    } : {}
  }
}

# Now we can combine the two maps, preferring the user supplied configuration.
# This is done by looping through the distinct keys of both maps,
# and using try() to get the user supplied value of that key if it exists,
# otherwise falling back to the existing value of the same key. One of these will always exist.
# Finally, we convert the map back to a list by accessing the values of the map.
locals {
  metrics_combined = {
    for k, v in var.diagnostic_settings : k => distinct([
      for k2 in distinct(
        concat(
          keys(local.metrics_existing[k]),
          keys(local.metrics_supplied[k])
        )
      ) : try(local.metrics_supplied[k][k2], local.metrics_existing[k][k2])
    ])
  }
}

# Final step! Use azapi_update_resource to update the diagnostic settings resource
# with the combined logs and metrics.
# This happens after both the azapi_resource creation and the azapi_resource data source,
# due to the for_each value being the azapi_resource data source above.
resource "azapi_update_resource" "diagnostic_settings" {
  for_each = data.azapi_resource.diagnostic_settings

  resource_id = each.value.id
  type        = each.value.type
  body = {
    properties = {
      metrics = local.metrics_combined[each.key]
      logs    = local.logs_combined_all[each.key]
    }
  }
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
