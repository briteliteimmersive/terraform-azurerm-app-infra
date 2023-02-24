locals {
  linux_function_app_diagnostic_settings_list = flatten([
    for linux_function_app_key, linux_function_app_config in local.linux_function_app_configs : [
      for diagnostics in coalesce(linux_function_app_config.diagnostic_settings, []) : {
        name                       = diagnostics.name
        linux_function_app_key     = linux_function_app_key
        diagnostic_key             = format("%s_%s", linux_function_app_key, diagnostics.name)
        log_analytics_workspace_id = diagnostics.log_analytics_workspace_id
        log = try(length(diagnostics.log), 0) > 0 ? [
          for log_details in diagnostics.log : {
            category         = lookup(log_details, "category", null)
            category_group   = lookup(log_details, "category_group ", null)
            retention_policy = lookup(log_details, "retention_policy", null)
            enabled          = lookup(log_details, "enabled", null)
          }
        ] : []
        metric = try(length(diagnostics.metric), 0) > 0 ? [
          for metric_details in diagnostics.metric : {
            category         = metric_details.category
            retention_policy = lookup(metric_details, "retention_policy", null)
            enabled          = lookup(metric_details, "enabled", null)
          }
        ] : []
      } if diagnostics.log_analytics_workspace_name != null
    ]
  ])

  linux_function_app_diagnostic_settings = {
    for diagnostics in local.linux_function_app_diagnostic_settings_list : diagnostics.diagnostic_key => diagnostics
  }
}

resource "azurerm_monitor_diagnostic_setting" "linux_function_app_diagnostic_settings" {
  for_each                   = local.linux_function_app_diagnostic_settings
  name                       = each.value.name
  target_resource_id         = azurerm_linux_function_app.linux_function_app[each.value.linux_function_app_key].id
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