variable "synapse_configs" {
  type = list(
    object(
      {
        resource_key                         = string
        name                                 = string
        resource_group_name                  = string
        location                             = string
        filesystem_name                      = string
        storage_account_id                   = string
        sql_administrator_login              = string
        sql_administrator_login_password     = string
        compute_subnet_id                    = string
        data_exfiltration_protection_enabled = bool
        linking_allowed_for_aad_tenant_ids   = list(string)
        managed_virtual_network_enabled      = bool
        public_network_access_enabled        = bool
        sql_identity_control_enabled         = bool
        customer_managed_key_name            = string
        spark_pools = list(object(
          {
            name                                = string
            node_size_family                    = string
            node_size                           = string
            node_count                          = number
            cache_size                          = number
            compute_isolation_enabled           = bool
            dynamic_executor_allocation_enabled = bool
            min_executors                       = number
            max_executors                       = number
            session_level_packages_enabled      = bool
            spark_log_folder                    = string
            spark_events_folder                 = string
            spark_version                       = string
            auto_pause = object({
              delay_in_minutes = number
            })
            auto_scale = object({
              min_node_count = number
              max_node_count = number
            })
            library_requirement = object({
              content   = string
              file_name = string
            })
            spark_config = object({
              content   = string
              file_name = string
            })
          }
        ))
        workspace_aad_admin = object(
          {
            login     = string
            object_id = string
          }
        )
        workspace_role_assignments = list(object(
          {
            role_name  = string
            object_ids = list(string)
          }
        ))
        firewall_rules = list(object(
          {
            name             = string
            start_ip_address = string
            end_ip_address   = string
          }
        ))
        identity = object(
          {
            type                = string
            user_identity_names = list(string)
          }
        )
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
        tags = map(string)
        role_assignments = list(
          object(
            {
              role_definition_id = string
              object_ids         = list(string)
            }
          )
        )
      }
    )
  )
}

variable "app_key_vault_id" {
  type = string
}

variable "admin_key_vault_id" {
  type = string
}