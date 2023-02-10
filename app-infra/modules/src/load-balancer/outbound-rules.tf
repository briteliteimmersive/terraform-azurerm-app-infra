locals {
  outbound_rules = flatten([
    for lb_k, lb_v in local.lb_configs_map :
    [
      for k_outbound, v_outbound in coalesce(lb_v.outbound_rules, []) :
      merge({
        lb_key                      = "${lb_v.resource_group_name}-${lb_v.name}"
        resource_group_name         = lb_v.resource_group_name
        lb_outbound_rules_key       = "${lb_v.resource_group_name}-${lb_v.name}-${v_outbound.name}"
        lb_backend_address_pool_key = v_outbound.backend_address_pool_name != null ? "${lb_v.resource_group_name}-${lb_v.name}-${v_outbound.backend_address_pool_name}" : null
      }, v_outbound)
    ]
  ])
  lb_outbound_rules_map = {
    for k, v in local.outbound_rules :
    v.lb_outbound_rules_key => v
  }
}

resource "azurerm_lb_outbound_rule" "lb_outbound_rule" {
  for_each                 = local.lb_outbound_rules_map
  name                     = each.value.name
  loadbalancer_id          = azurerm_lb.lb[each.value.lb_key].id
  protocol                 = each.value.protocol
  backend_address_pool_id  = each.value.backend_address_pool_name != null ? azurerm_lb_backend_address_pool.lb_backend_address_pool[each.value.lb_backend_address_pool_key].id : null
  enable_tcp_reset         = each.value.enable_tcp_reset
  allocated_outbound_ports = each.value.allocated_outbound_ports
  idle_timeout_in_minutes  = each.value.idle_timeout_in_minutes
  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configuration != null ? each.value.frontend_ip_configuration : []
    content {
      name = frontend_ip_configuration.value
    }
  }
}