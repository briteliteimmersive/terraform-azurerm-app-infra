variable "keyvault_configs" {
  type = list(
    object(
      {
        resource_key                    = string
        name                            = string
        resource_group_name             = string
        location                        = string
        sku_name                        = string
        enabled_for_deployment          = bool
        enabled_for_disk_encryption     = bool
        enabled_for_template_deployment = bool
        enable_rbac_authorization       = bool
        purge_protection_enabled        = bool
        soft_delete_retention_days      = number
        network_acls = object(
          {
            bypass                     = string
            default_action             = string
            ip_rules                   = list(string)
            virtual_network_subnet_ids = list(string)
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
        role_assignments = list(
          object(
            {
              role_definition_id = string
              object_ids         = list(string)
            }
          )
        )
        tags = map(string)
  }))
}









