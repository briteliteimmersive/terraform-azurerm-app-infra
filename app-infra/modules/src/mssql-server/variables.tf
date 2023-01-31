variable "mssql_server_configs" {
  type = list(object(
    {
      resource_key                 = string
      name                         = string
      resource_group_name          = string
      location                     = string
      version                      = string
      connection_policy            = string #Default,Proxy,Redirect
      minimum_tls_version          = string
      administrator_login          = string
      administrator_login_password = string
      connection_policy            = string
      primary_user_identity_name   = string
      azuread_administrator = object(
        {
          login_username              = string
          object_id                   = string
          azuread_authentication_only = bool
        }
      )
      identity = object(
        {
          type                = string
          user_identity_names = list(string)
        }
      )
      firewall_rules = list(object(
        {
          name             = string
          start_ip_address = string
          end_ip_address   = string
        }
      ))
      virtual_network_rules = list(object(
        {
          name      = string
          subnet_id = string
        }
      ))
      databases = list(object({
        name                        = string
        max_size_gb                 = number
        sku_name                    = string
        elastic_pool_name           = string
        zone_redundant              = bool
        auto_pause_delay_in_minutes = string
        collation                   = string
        geo_backup_enabled          = string
        license_type                = string
        read_replica_count          = string
        storage_account_type        = string
        min_capacity                = number
        short_term_retention_policy = object({
          retention_days = number
        })
        long_term_retention_policy = object(
          {
            weekly_retention  = string
            monthly_retention = string
            yearly_retention  = string
            week_of_year      = number
          }
        )
        threat_detection_policy = object(
          {
            state                      = string
            disabled_alerts            = string
            email_account_admins       = string
            email_addresses            = string
            retention_days             = number
            storage_account_access_key = string
            storage_endpoint           = string
          }
        )
      }))
      elastic_pools = list(object(
        {
          name                           = string
          license_type                   = string
          max_size_gb                    = number
          max_size_bytes                 = number
          maintenance_configuration_name = string
          zone_redundant                 = bool
          sku = object({
            name     = string
            tier     = string
            family   = string
            capacity = number
          })
          per_database_settings = object({
            min_capacity = number
            max_capacity = number
          })
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
  ))
}

variable "app_key_vault_id" {
  type    = string
  default = null
}