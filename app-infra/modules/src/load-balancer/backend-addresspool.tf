locals {
  backend_address_pool = flatten([
    for lb_key, lb_config in local.lb_configs_map :
    [
      for backend_address_pool_config in coalesce(lb_config.backend_address_pool, []) :
      [
        merge({
          lb_key                      = lb_key
          lb_backend_address_pool_key = lower(format("%s/%s", lb_key, backend_address_pool_config.name))
        }, backend_address_pool_config)
      ]
    ] if lb_config.backend_address_pool != null
  ])

  backend_address_pool_map = {
    for backend_pool in local.backend_address_pool : backend_pool.lb_backend_address_pool_key => backend_pool
  }

  backend_address_pool_address = flatten([
    for lb_key, lb_config in local.lb_configs_map :
    [
      for backend_address_pool_config in coalesce(lb_config.backend_address_pool, []) :
      [
        for backend_address_pool_addr in coalesce(backend_address_pool_config.backend_address_pool_address, []) :
        [
          merge({
            lb_key                           = lb_key
            resource_group_name              = lb_config.resource_group_name
            lb_name                          = lb_config.name
            lb_backend_address_pool_key      = lower(format("%s/%s", lb_key, backend_address_pool_config.name))
            backend_address_pool_name        = backend_address_pool_config.name
            backend_address_pool_address_key = lower(format("%s/%s/%s", lb_key, backend_address_pool_config.name, backend_address_pool_addr.name))
          }, backend_address_pool_addr)
        ]
      ]
    ] if lb_config.backend_address_pool != null
  ])
  backend_address_pool_address_map = {
    for backend_address_pool_addr in local.backend_address_pool_address : backend_address_pool_addr.backend_address_pool_address_key => backend_address_pool_addr
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend_address_pool" {
  for_each        = local.backend_address_pool_map
  loadbalancer_id = azurerm_lb.lb[each.value.lb_key].id
  name            = each.value.name

  dynamic "tunnel_interface" {
    for_each = each.value.tunnel_interface != null ? each.value.tunnel_interface : []
    content {
      identifier = tunnel_interface.value.identifier
      type       = tunnel_interface.value.type
      protocol   = tunnel_interface.value.protocol
      port       = tunnel_interface.value.port
    }
  }
}

resource "azurerm_lb_backend_address_pool_address" "lb_backend_address_pool_address" {
  for_each                = local.backend_address_pool_address_map
  name                    = each.value.name
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_address_pool[each.value.lb_backend_address_pool_key].id
  virtual_network_id      = each.value.virtual_network_id
  ip_address              = each.value.ip_address
}