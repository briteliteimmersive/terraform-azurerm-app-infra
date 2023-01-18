variable "aks_configs" {
  type = object({
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
    network_rules = optional(object({
      public_ip_ranges = list(string)
      }), {
      public_ip_ranges = []
    })
    clusters = list(
      object(
        {
          name                             = string
          resource_group_name              = optional(string)
          subnet_name                      = string
          dns_prefix                       = optional(string)
          automatic_channel_upgrade        = optional(bool)
          sku_tier                         = optional(string)
          kubernetes_version               = optional(string)
          http_application_routing_enabled = optional(bool)
          network_profile = optional(object(
            {
              network_plugin     = string
              network_mode       = optional(string)
              network_policy     = optional(string)
              dns_service_ip     = optional(string)
              docker_bridge_cidr = optional(string)
              pod_cidr           = optional(string)
              service_cidr       = optional(string)
              outbound_type      = optional(string)
            }
          ))
          identity = optional(object(
            {
              type                = string
              user_identity_names = optional(list(string), [])
            }
            ), {
            type = "SystemAssigned"
          })
          default_node_pool = optional(object(
            {
              name                 = string
              vm_size              = string
              enable_auto_scaling  = optional(bool, true)
              max_count            = optional(number, 3)
              min_count            = optional(number, 1)
              node_labels          = optional(map(string), {})
              orchestrator_version = optional(string)
            }
            ), {
            enable_auto_scaling  = true
            max_count            = 3
            min_count            = 1
            name                 = "defaultpool"
            node_labels          = {}
            orchestrator_version = null
            vm_size              = "Standard_D2s_v3"
          })
          user_node_pools = optional(list(object(
            {
              name                 = string
              vm_size              = string
              min_count            = optional(number)
              max_count            = optional(number)
              enable_auto_scaling  = optional(bool)
              node_labels          = optional(map(string), {})
              node_taints          = optional(list(string), [])
              orchestrator_version = optional(string)
              os_disk_size_gb      = optional(string)
              os_disk_type         = optional(string)
              max_pods             = optional(number)
              mode                 = optional(string)
            }
          )), [])
          oms_agent = optional(object(
            {
              log_analytics_workspace_name = string
            }
          ))
          tags = optional(map(string), {})
        }
      )
    )
  })

  default = null
}

locals {

  aks_inputs              = var.aks_configs
  aks_rgp                 = try(local.aks_inputs.resource_group_name, null)
  aks_network_rules       = try(local.aks_inputs.network_rules, null)
  aks_diagnostic_settings = try(local.aks_inputs.diagnostic_settings, null)
  aks_role_assignments    = try(local.aks_inputs.role_assignments, null)
  aks_tags                = try(local.aks_inputs.tags, {})
  aks_list                = try(local.aks_inputs.clusters, [])


  aks_resource_groups = distinct([
    for aks in local.aks_list : {
      name             = coalesce(aks.resource_group_name, local.aks_rgp)
      resource_key     = lower(coalesce(aks.resource_group_name, local.aks_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])

  aks_configs_map = {
    for aks in local.aks_list : aks.name => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(aks.resource_group_name, local.aks_rgp),
        aks.name
      ))
      resource_group_name               = module.resource_groups.outputs[lower(coalesce(aks.resource_group_name, local.aks_rgp))].name
      location                          = local.location
      role_based_access_control_enabled = true
      tags = merge(
        local.aks_tags,
        aks.tags,
        local.common_resource_tags
      )
      disk_encryption_set_id = local.admin_disk_encryption_set_id
      ### When public_network_access_enabled is set to true, 0.0.0.0/32 must be added to api_server_authorized_ip_ranges.
      api_server_authorized_ip_ranges = distinct(try(concat(
        local.network_rules.public_ip_ranges,
        local.aks_network_rules.public_ip_ranges
        ["0.0.0.0/32"]
      ), []))

      diagnostic_settings = try(length(local.aks_diagnostic_settings) > 0, false) ? [
        for setting in local.aks_diagnostic_settings.settings : {
          name   = setting.name
          log    = setting.log
          metric = setting.metric
          log_analytics_workspace_name = try(
            local.aks_diagnostic_settings.log_analytics_workspace_name,
            null
          )
          log_analytics_workspace_id = try(
            local.aks_diagnostic_settings.log_analytics_workspace_id,
            # module.log_analytics.outputs[local.aks_diagnostic_settings.log_analytics_workspace_name].id, ## Needs fixing
            null
          )
        }
      ] : []
      role_assignments                 = local.aks_role_assignments
      name                             = aks.name
      vnet_subnet_id                   = try(local.subnet_ids_by_name[aks.subnet_name], null)
      route_table_id                   = try(local.subnet_ids_by_name[aks.subnet_name], null) != null ? try(local.udr_ids_by_subnet_name[aks.subnet_name]) : null
      dns_prefix                       = coalesce(aks.dns_prefix, aks.name)
      automatic_channel_upgrade        = aks.automatic_channel_upgrade
      sku_tier                         = aks.sku_tier
      kubernetes_version               = aks.kubernetes_version
      http_application_routing_enabled = aks.http_application_routing_enabled
      network_profile                  = aks.network_profile
      identity                         = aks.identity
      default_node_pool                = aks.default_node_pool
      user_node_pools                  = aks.user_node_pools
      oms_agent                        = null
      # oms_agent = try(length(aks.oms_agent) > 0, false) ? {
      #   log_analytics_workspace_id = module.log_analytics.outputs[aks.additional_settings.oms_agent.log_analytics_workspace_name].id,
      # } : null
    }
  }

  aks_configs = values(local.aks_configs_map)

}

module "aks_clusters" {
  source             = "./modules/src/aks"
  aks_configs        = local.aks_configs
  app_key_vault_id   = local.infra_keyvault_id
  admin_key_vault_id = local.admin_key_vault_id
}