variable "lb_configs" {
  type = list(
    object(
      {
        resource_key        = string
        name                = string
        resource_group_name = string
        location            = string
        sku                 = string
        sku_tier            = string
        edge_zone           = string
        frontend_ip_configuration = list(
          object(
            {
              name                                               = string
              zones                                              = list(string)
              gateway_load_balancer_frontend_ip_configuration_id = string
              subnet_id                                          = string
              private_ip_address                                 = string
              private_ip_address_allocation                      = string
              private_ip_address_version                         = string
              public_ip_address_id                               = string
              public_ip_prefix_id                                = string
            }
          )
        )
        backend_address_pool = list(object({
          name = string
          tunnel_interface = list(object(
            {
              identifier = string
              type       = string
              protocol   = string
              port       = number
            }
          ))
          backend_address_pool_address = list(object(
            {
              name               = string
              virtual_network_id = string
              ip_address         = string
            }
          ))
        }))
        nat_rules = list(object({
          name                           = string
          protocol                       = string
          frontend_port_start            = string
          frontend_port_end              = string
          frontend_port                  = string
          backend_port                   = string
          backend_address_pool_name      = string
          frontend_ip_configuration_name = string
          idle_timeout_in_minutes        = number
          enable_floating_ip             = bool
          enable_tcp_reset               = bool
        }))
        nat_pools = list(object({
          name                    = string
          protocol                = string
          frontend_port_start     = number
          frontend_port_end       = number
          backend_port            = number
          idle_timeout_in_minutes = number
          floating_ip_enabled     = bool
          tcp_reset_enabled       = bool
        }))
        outbound_rules = list(object({
          name                      = string
          protocol                  = string
          backend_address_pool_name = string
          frontend_ip_configuration = list(string)
          enable_tcp_reset          = bool
          allocated_outbound_ports  = number
          idle_timeout_in_minutes   = number
        }))
        probes = list(object({
          name                = string
          port                = number
          protocol            = string
          request_path        = string
          interval_in_seconds = number
          number_of_probes    = number
        }))
        rules = list(object({
          name                           = string
          protocol                       = string
          frontend_port                  = number
          backend_port                   = number
          frontend_ip_configuration_name = string
          backend_address_pool_name      = list(string)
          probe_name                     = string
          enable_floating_ip             = bool
          idle_timeout_in_minutes        = number
          load_distribution              = string
          disable_outbound_snat          = bool
          enable_tcp_reset               = bool
        }))
        diagnostic_settings = list(object(
          {
            name                         = string
            log_analytics_workspace_name = string
            log_analytics_workspace_id   = string
            log = list(object(
              {
                category       = string
                category_group = string
                enabled        = bool
                retention_policy = object(
                  {
                    enabled = bool
                    days    = number
                  }
                )
              }
            ))
            metric = list(object(
              {
                category = string
                enabled  = bool
                retention_policy = object(
                  {
                    enabled = bool
                    days    = number
                  }
                )
              }
            ))
          }
        ))
        role_assignments = list(
          object(
            {
              role_definition_id = string
              object_ids         = list(string)
            }
          )
        )
        tags = map(string)
      }
    )
  )
}