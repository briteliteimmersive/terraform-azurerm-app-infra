locals {
  aks_diagnostic_settings_list = flatten([
    for aks_key, aks_config in local.aks_configs : [
      for diagnostics in aks_config.diagnostic_settings : {
        name                       = diagnostics.name
        aks_key                    = aks_key
        diagnostic_key             = format("%s/%s", aks_key, diagnostics.name)
        log_analytics_workspace_id = diagnostics.log_analytics_workspace_id
        log                        = diagnostics.log
        metric                     = diagnostics.metric
      } if diagnostics.log_analytics_workspace_name != null
    ]
  ])

  aks_diagnostic_settings = {
    for diagnostics in local.aks_diagnostic_settings_list : diagnostics.diagnostic_key => diagnostics
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks_diagnostic_settings" {
  for_each                   = local.aks_diagnostic_settings
  name                       = each.value.name
  target_resource_id         = azurerm_kubernetes_cluster.aks_cluster[each.value.aks_key].id
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