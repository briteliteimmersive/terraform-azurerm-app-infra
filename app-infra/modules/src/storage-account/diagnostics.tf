locals {
  storage_diagnostic_settings_list = flatten([
    for storage_key, storage_config in local.storage_config : [
      for diagnostics in storage_config.diagnostic_settings : {
        name                       = diagnostics.name
        storage_key                = storage_key
        diagnostic_key             = format("%s/%s", storage_key, diagnostics.name)
        log_analytics_workspace_id = diagnostics.log_analytics_workspace_id
        log                        = diagnostics.log
        metric                     = diagnostics.metric
      } if diagnostics.log_analytics_workspace_name != null
    ]
  ])

  storage_diagnostic_settings = {
    for diagnostics in local.storage_diagnostic_settings_list : diagnostics.diagnostic_key => diagnostics
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage_diagnostic_settings" {
  for_each                   = local.storage_diagnostic_settings
  name                       = each.value.name
  target_resource_id         = azurerm_storage_account.storage_account[each.value.storage_key].id
  log_analytics_workspace_id = each.value.log_analytics_workspace_id

  dynamic "log" {
    for_each = try(length(each.value.log), 0) > 0 ? each.value.log : []

    content {
      category       = lookup(log.value, "category", null)
      category_group = lookup(log.value, "category_group", null)
      enabled        = lookup(log.value, "enabled", true)

      dynamic "retention_policy" {
        for_each = try(length(log.value.retention_policy), 0) > 0 ? [log.value.retention_policy] : []

        content {
          enabled = lookup(retention_policy.value, "enabled", null)
          days    = lookup(retention_policy.value, "days", null)
        }
      }

    }
  }

  dynamic "metric" {
    for_each = try(length(each.value.metric), 0) > 0 ? each.value.metric : []

    content {
      category = metric.value.category
      enabled  = lookup(metric.value, "enabled", true)

      dynamic "retention_policy" {
        for_each = try(length(metric.value.retention_policy), 0) > 0 ? [metric.value.retention_policy] : []

        content {
          enabled = lookup(retention_policy.value, "enabled", null)
          days    = lookup(retention_policy.value, "days", null)
        }
      }

    }
  }
}