variable "lb_configs" {
  type = object(
    {
      resource_group_name = string
      diagnostic_settings = optional(object(
        {
          log_analytics_workspace_name = optional(string)
          log_analytics_workspace_id   = optional(string)
          settings = list(object(
            {
              name = string
              log = optional(list(object(
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
              )), [])
              metric = optional(list(object(
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
              )), [])
            }
          ))
        }
      ))
      role_assignments = optional(list(
        object(
          {
            role_definition_id = string
            object_ids         = list(string)
          }
        )
      ), [])
      tags = optional(map(string), {})
      load_balancers = list(object({
        name                = string
        resource_group_name = optional(string)
        sku                 = optional(string, "Standard")
        sku_tier            = optional(string, "Regional")
        edge_zone           = optional(string)
        frontend_ip_configuration = optional(list(object({
          name                          = string
          zones                         = optional(list(string), [])
          subnet_name                   = string
          private_ip_address            = optional(string)
          private_ip_address_allocation = optional(string, "Dynamic")
          private_ip_address_version    = optional(string, "IPv4")
        })), [])
        backend_address_pool = optional(list(object(
          {
            name = string
            tunnel_interface = optional(list(object({
              identifier = string
              type       = string
              protocol   = string
              port       = number
            })), [])
          }
        )))
        probes = optional(list(object({
          name                = string
          port                = number
          protocol            = optional(string, "Tcp")
          request_path        = optional(string)
          interval_in_seconds = optional(number)
          number_of_probes    = optional(number)
        })), [])
        rules = optional(list(object(
          {
            name                           = string
            protocol                       = optional(string, "Tcp")
            frontend_port                  = optional(number)
            backend_port                   = number
            frontend_ip_configuration_name = string
            backend_address_pool_name      = optional(list(string), [])
            probe_name                     = optional(string)
            enable_floating_ip             = optional(string)
            idle_timeout_in_minutes        = optional(number)
            load_distribution              = optional(string)
            disable_outbound_snat          = optional(bool)
            enable_tcp_reset               = optional(bool)
          }
        )))
        nat_rules = optional(list(object({
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
        })), [])
        nat_pools = optional(list(object({
          name                    = string
          protocol                = string
          frontend_port_start     = number
          frontend_port_end       = number
          backend_port            = number
          idle_timeout_in_minutes = number
          floating_ip_enabled     = bool
          tcp_reset_enabled       = bool
        })), [])
        outbound_rules = optional(list(object({
          name                      = string
          protocol                  = string
          backend_address_pool_name = string
          frontend_ip_configuration = list(string)
          enable_tcp_reset          = bool
          allocated_outbound_ports  = number
          idle_timeout_in_minutes   = number
        })), [])
        tags = optional(map(string), {})
      }))
    }
  )

  default = null
}

locals {
  lb_inputs              = var.lb_configs
  lb_rgp                 = try(local.lb_inputs.resource_group_name, null)
  lb_network_rules       = try(local.lb_inputs.network_rules, null)
  lb_diagnostic_settings = try(local.lb_inputs.diagnostic_settings, null)
  lb_role_assignments    = try(local.lb_inputs.role_assignments, null)
  lb_tags                = try(local.lb_inputs.tags, {})
  lb_list                = try(local.lb_inputs.load_balancers, [])


  lb_resource_groups = distinct([
    for load_balancer in local.lb_list : {
      name             = coalesce(load_balancer.resource_group_name, local.lb_rgp)
      resource_key     = lower(coalesce(load_balancer.resource_group_name, local.lb_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])

  lb_configs_map = {
    for load_balancer in local.lb_list : load_balancer.name => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(load_balancer.resource_group_name, local.lb_rgp),
        load_balancer.name
      ))
      resource_group_name       = module.resource_groups.outputs[lower(coalesce(load_balancer.resource_group_name, local.lb_rgp))].name
      location                  = local.location
      enable_rbac_authorization = true
      tags = merge(
        local.lb_tags,
        load_balancer.tags,
        local.common_resource_tags
      )
      diagnostic_settings = try(length(local.lb_diagnostic_settings) > 0, false) ? [
        for setting in local.lb_diagnostic_settings.settings : {
          name   = setting.name
          log    = setting.log
          metric = setting.metric
          log_analytics_workspace_name = try(
            local.lb_diagnostic_settings.log_analytics_workspace_name,
            null
          )
          log_analytics_workspace_id = try(
            local.lb_diagnostic_settings.log_analytics_workspace_id,
            # module.log_analytics.outputs[local.lb_diagnostic_settings.log_analytics_workspace_name].id, ## Needs fixing
            null
          )
        }
      ] : []
      role_assignments = local.lb_role_assignments
      name             = load_balancer.name
      sku              = load_balancer.sku
      sku_tier         = load_balancer.sku_tier
      edge_zone        = load_balancer.edge_zone
      frontend_ip_configuration = try(length(load_balancer.frontend_ip_configuration), 0) > 0 ? [
        for frontend_ip_config in load_balancer.frontend_ip_configuration : merge(frontend_ip_config, {
          subnet_id                                          = local.subnet_ids_by_name[frontend_ip_config.subnet_name]
          public_ip_address_id                               = null
          public_ip_prefix_id                                = null
          gateway_load_balancer_frontend_ip_configuration_id = null
        })
      ] : []
      backend_address_pool = try(length(load_balancer.backend_address_pool), 0) > 0 ? [
        for backend_pool in load_balancer.backend_address_pool : merge(backend_pool, {
          backend_address_pool_address = flatten([
            for backend_address_pool_key, backend_address_pool_address_config in local.loadbalancer_backend_pool_address : backend_address_pool_address_config if backend_address_pool_key == format("%s-%s-%s", lower(coalesce(load_balancer.resource_group_name, local.lb_rgp)), load_balancer.name, backend_pool.name)
          ])
        })
      ] : []
      probes = load_balancer.probes
      rules = try(length(load_balancer.rules), 0) > 0 ? [
        for rule in load_balancer.rules : merge(rule, {
          frontend_port = coalesce(rule.frontend_port, rule.backend_port)
        })
      ] : []
      nat_rules      = load_balancer.nat_rules
      outbound_rules = load_balancer.outbound_rules
      nat_pools      = load_balancer.nat_pools
    }
  }

  lb_configs = values(local.lb_configs_map)

}

module "loadbalancer" {
  source     = "./modules/src/load-balancer"
  lb_configs = local.lb_configs
}