locals {
  lb_nat_pool = flatten([
    for lb_key, lb_config in local.lb_configs_map :
    [
      for nat_pool_key, nat_pool in coalesce(lb_config.nat_pools, []) : [
        merge({
          lb_key                         = lb_key
          resource_group_name            = lb_config.resource_group_name
          lb_name                        = lb_config.name
          frontend_ip_configuration_name = lb_config.frontend_ip_configuration_name
          nat_pool_key                   = lower(format("%s/%s/%s", lb_key, lb_config.frontend_ip_configuration_name, nat_pool.name))
        }, nat_pool)
      ]
    ] if try(length(lb_config.nat_pools), 0) > 0
  ])
  lb_nat_pool_map = {
    for nat_pool in local.lb_nat_pool : nat_pool.nat_pool_key => nat_pool
  }
}

resource "azurerm_lb_nat_pool" "lb_nat_pool" {
  for_each                       = local.lb_nat_pool_map
  resource_group_name            = each.value.resource_group_name
  loadbalancer_id                = azurerm_lb.lb[each.value.lb_key].id
  name                           = each.value.name
  protocol                       = each.value.protocol
  frontend_port_start            = each.value.frontend_port_start
  frontend_port_end              = each.value.frontend_port_end
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
  floating_ip_enabled            = each.value.floating_ip_enabled
  tcp_reset_enabled              = each.value.tcp_reset_enabled
}