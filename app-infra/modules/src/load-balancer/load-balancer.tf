locals {
  lb_configs = var.lb_configs
  lb_configs_map = {
    for lb_config in local.lb_configs : lb_config.resource_key => lb_config
  }
}

resource "azurerm_lb" "lb" {
  for_each = local.lb_configs_map

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  sku                 = each.value.sku
  sku_tier            = each.value.sku_tier
  edge_zone           = each.value.edge_zone

  dynamic "frontend_ip_configuration" {
    for_each = coalesce(each.value.frontend_ip_configuration, [])

    content {
      name                                               = frontend_ip_configuration.value.name
      zones                                              = frontend_ip_configuration.value.zones
      gateway_load_balancer_frontend_ip_configuration_id = frontend_ip_configuration.value.gateway_load_balancer_frontend_ip_configuration_id
      subnet_id                                          = frontend_ip_configuration.value.subnet_id
      private_ip_address                                 = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation                      = frontend_ip_configuration.value.private_ip_address_allocation
      private_ip_address_version                         = frontend_ip_configuration.value.private_ip_address_version
      public_ip_address_id                               = frontend_ip_configuration.value.public_ip_address_id
      public_ip_prefix_id                                = frontend_ip_configuration.value.public_ip_prefix_id
    }
  }

  tags = each.value.tags
}

