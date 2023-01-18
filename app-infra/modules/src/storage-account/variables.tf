variable "storage_acc_configs" {
  type = list(
    object(
      {
        resource_key                      = string
        name                              = string
        resource_group_name               = string
        location                          = string
        account_tier                      = string
        account_replication_type          = string
        account_kind                      = string
        access_tier                       = string
        cross_tenant_replication_enabled  = bool
        edge_zone                         = string
        enable_https_traffic_only         = bool
        shared_access_key_enabled         = bool
        min_tls_version                   = string
        is_hns_enabled                    = bool
        large_file_share_enabled          = bool
        allow_nested_items_to_be_public   = bool
        infrastructure_encryption_enabled = bool
        blob_properties = object(
          {
            versioning_enabled  = bool
            change_feed_enabled = bool
            container_delete_retention_policy = object(
              {
                days = number
              }
            )
            delete_retention_policy = object(
              {
                days = number
              }
            )
          }
        )
        network_rules = object(
          {
            default_action             = string
            bypass                     = list(string)
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
        tags = map(string)
        storage_containers = list(object({
          name                  = string
          container_access_type = string
          metadata              = map(string)
        }))
        file_shares = list(
          object(
            {
              name  = string
              quota = number
            }
          )
        )
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
  type    = string
  default = null
}