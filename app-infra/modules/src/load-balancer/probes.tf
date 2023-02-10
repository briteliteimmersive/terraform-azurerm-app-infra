locals {
  probes = flatten([
    for lb_key, lb_config in local.lb_configs_map :
    [
      for probe_key, probe_config in coalesce(lb_config.probes, []) :
      merge({
        lb_key              = lb_key
        resource_group_name = lb_config.resource_group_name
        probe_key           = lower(format("%s/%s", lb_key, probe_config.name))
      }, probe_config)
    ]
  ])

  lb_probes_map = {
    for probe_config in local.probes : probe_config.probe_key => probe_config
  }

  rules = flatten([
    for lb_key, lb_config in local.lb_configs_map :
    [
      for lb_rule_key, lb_rule_config in coalesce(lb_config.rules, []) :
      merge({
        lb_key              = lb_key
        resource_group_name = lb_config.resource_group_name
        probe_key           = lb_rule_config.probe_name != null ? lower(format("%s/%s", lb_key, lb_rule_config.probe_name)) : null
        lb_rule_key         = lower(format("%s/%s", lb_key, lb_rule_config.name))
        lb_backend_address_pool_key = [
          for backend_address_pool in coalesce(lb_rule_config.backend_address_pool_name, []) :
          azurerm_lb_backend_address_pool.lb_backend_address_pool[lower(format("%s/%s", lb_key, backend_address_pool))].id
        ]

      }, lb_rule_config)
    ]
  ])
  lb_rules_map = {
    for rule in local.rules : rule.lb_rule_key => rule
  }
}

resource "azurerm_lb_probe" "lb_probe" {
  for_each            = local.lb_probes_map
  name                = each.value.name
  loadbalancer_id     = azurerm_lb.lb[each.value.lb_key].id
  port                = each.value.port
  protocol            = each.value.protocol
  request_path        = each.value.request_path
  interval_in_seconds = each.value.interval_in_seconds
  number_of_probes    = each.value.number_of_probes
}

resource "azurerm_lb_rule" "lb_rule" {
  for_each                       = local.lb_rules_map
  loadbalancer_id                = azurerm_lb.lb[each.value.lb_key].id
  name                           = each.value.name
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  enable_floating_ip             = each.value.enable_floating_ip
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
  load_distribution              = each.value.load_distribution
  disable_outbound_snat          = each.value.disable_outbound_snat
  enable_tcp_reset               = each.value.enable_tcp_reset
  probe_id                       = each.value.probe_name != null ? azurerm_lb_probe.lb_probe[each.value.probe_key].id : null
  backend_address_pool_ids       = each.value.backend_address_pool_name != null ? each.value.lb_backend_address_pool_key : null
}