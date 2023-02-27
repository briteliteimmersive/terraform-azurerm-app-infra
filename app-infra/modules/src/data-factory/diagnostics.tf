# locals {
#   data_factory_diagnostic_settings_list = flatten([
#     for data_factory_key, data_factory_config in local.data_factory_configs : [
#       for diagnostics in data_factory_config.diagnostic_settings : {
#         name                       = diagnostics.name
#         data_factory_key           = data_factory_key
#         diagnostic_key             = format("%s_%s", data_factory_key, diagnostics.name)
#         log_analytics_workspace_id = diagnostics.log_analytics_workspace_id
#         log = try(length(diagnostics.log), 0) > 0 ? [
#           for log_details in diagnostics.log : {
#             category         = lookup(log_details, "category", null)
#             category_group   = lookup(log_details, "category_group ", null)
#             retention_policy = lookup(log_details, "retention_policy", null)
#             enabled          = lookup(log_details, "enabled", null)
#           }
#           ] : [
#           for category in data.azurerm_monitor_diagnostic_categories.diagnostic_categories[data_factory_key].log_category_types : {
#             category         = category
#             category_group   = null
#             retention_policy = null
#             enabled          = true
#           }
#         ]
#         metric = try(length(diagnostics.metric), 0) > 0 ? [
#           for metric_details in diagnostics.metric : {
#             category         = metric_details.category
#             retention_policy = lookup(metric_details, "retention_policy", null)
#             enabled          = lookup(metric_details, "enabled", null)
#           }
#           ] : [
#           for category in data.azurerm_monitor_diagnostic_categories.diagnostic_categories[data_factory_key].metrics : {
#             category         = category
#             retention_policy = null
#             enabled          = true
#           }
#         ]
#       } if diagnostics.log_analytics_workspace_name != null
#     ]
#   ])

#   data_factory_diagnostic_settings = {
#     for diagnostics in local.data_factory_diagnostic_settings_list : diagnostics.diagnostic_key => diagnostics
#   }
# }

# data "azurerm_monitor_diagnostic_categories" "diagnostic_categories" {
#   for_each    = local.data_factory_configs
#   resource_id = azurerm_data_factory.data_factory[each.key].id
# }

# resource "azurerm_monitor_diagnostic_setting" "data_factory_diagnostic_settings" {
#   for_each                   = local.data_factory_diagnostic_settings
#   name                       = each.value.name
#   target_resource_id         = azurerm_data_factory.data_factory[each.value.data_factory_key].id
#   log_analytics_workspace_id = each.value.log_analytics_workspace_id

#   dynamic "log" {
#     for_each = try(length(each.value.log), 0) > 0 ? each.value.log : []

#     content {
#       category       = lookup(log.value, "category", null)
#       category_group = lookup(log.value, "category_group", null)
#       enabled        = lookup(log.value, "enabled", true)

#       dynamic "retention_policy" {
#         for_each = try(length(log.value.retention_policy), 0) > 0 ? [log.value.retention_policy] : []

#         content {
#           enabled = lookup(retention_policy.value, "enabled", null)
#           days    = lookup(retention_policy.value, "days", null)
#         }
#       }

#     }
#   }

#   dynamic "metric" {
#     for_each = try(length(each.value.metric), 0) > 0 ? each.value.metric : []

#     content {
#       category = metric.value.category
#       enabled  = lookup(metric.value, "enabled", true)

#       dynamic "retention_policy" {
#         for_each = try(length(metric.value.retention_policy), 0) > 0 ? [metric.value.retention_policy] : []

#         content {
#           enabled = lookup(retention_policy.value, "enabled", null)
#           days    = lookup(retention_policy.value, "days", null)
#         }
#       }

#     }
#   }
# }