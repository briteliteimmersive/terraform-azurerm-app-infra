locals {
  nat_rules = flatten([
    for lb_key, lb_config in local.lb_configs_map :
    [
      for nat_rule_key, nat_rule in coalesce(lb_config.nat_rules, []) :
      merge({
        lb_key                      = lb_key
        resource_group_name         = lb_config.resource_group_name
        lb_nat_rules_key            = lower(format("%s/%s", lb_key, nat_rule.name))
        lb_backend_address_pool_key = nat_rule.backend_address_pool_name != null ? lower(format("%s/%s", lb_key, nat_rule.backend_address_pool_name)) : null
      }, nat_rule)
    ]
  ])
  lb_nat_rules_map = {
    for nat_rule_key, nat_rule in local.nat_rules :
    nat_rule.lb_nat_rules_key => nat_rule
  }
}

resource "azurerm_lb_nat_rule" "lb_nat_rule" {
  for_each                       = local.lb_nat_rules_map
  resource_group_name            = each.value.resource_group_name
  loadbalancer_id                = azurerm_lb.lb[each.value.lb_key].id
  name                           = each.value.name
  protocol                       = each.value.protocol
  frontend_port_start            = each.value.frontend_port_start
  frontend_port_end              = each.value.frontend_port_end
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  backend_address_pool_id        = each.value.backend_address_pool_name != null ? azurerm_lb_backend_address_pool.lb_backend_address_pool[each.value.lb_backend_address_pool_key].id : null
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
  enable_floating_ip             = each.value.enable_floating_ip
  enable_tcp_reset               = each.value.enable_tcp_reset
}