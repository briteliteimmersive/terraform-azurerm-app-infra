variable "aks_configs" {
  type = list(
    object(
      {
        resource_key                      = string
        name                              = string
        location                          = string
        resource_group_name               = string
        dns_prefix                        = string
        automatic_channel_upgrade         = string
        sku_tier                          = string
        vnet_subnet_id                    = string
        route_table_id                    = string
        api_server_authorized_ip_ranges   = list(string)
        disk_encryption_set_id            = string
        role_based_access_control_enabled = bool
        http_application_routing_enabled  = bool
        kubernetes_version                = string
        oms_agent = object(
          {
            log_analytics_workspace_id = string
          }
        )
        identity = object(
          {
            type                = string
            user_identity_names = list(string)
          }
        )
        network_profile = object(
          {
            network_plugin     = string
            outbound_type      = string
            network_policy     = string
            dns_service_ip     = string
            docker_bridge_cidr = string
            pod_cidr           = string
            service_cidr       = string
          }
        )
        default_node_pool = object(
          {
            name                 = string
            vm_size              = string
            enable_auto_scaling  = bool
            min_count            = string
            max_count            = string
            orchestrator_version = string
            node_labels          = map(string)
          }
        )
        user_node_pools = list(object(
          {
            name                 = string
            mode                 = string
            vm_size              = string
            orchestrator_version = string
            os_disk_size_gb      = number
            os_disk_type         = string
            min_count            = number
            max_count            = number
            enable_auto_scaling  = bool
            node_labels          = map(string)
            node_taints          = list(string)
            max_pods             = number
          }
        ))
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

variable "app_key_vault_id" {
  type    = string
  default = null
}

variable "admin_key_vault_id" {
  type    = string
  default = null
}