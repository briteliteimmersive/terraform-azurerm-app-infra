locals {
  service_plan_configs = {
    for service_plan_config in var.service_plan_configs : service_plan_config.resource_key => service_plan_config
  }
}

resource "azurerm_service_plan" "service_plan" {
  for_each                     = local.service_plan_configs
  name                         = each.value.name
  resource_group_name          = each.value.resource_group_name
  location                     = each.value.location
  os_type                      = each.value.os_type
  sku_name                     = each.value.sku_name
  app_service_environment_id   = each.value.app_service_environment_id
  per_site_scaling_enabled     = each.value.per_site_scaling_enabled
  worker_count                 = each.value.worker_count
  zone_balancing_enabled       = each.value.zone_balancing_enabled
  maximum_elastic_worker_count = each.value.maximum_elastic_worker_count
  tags                         = each.value.tags
}