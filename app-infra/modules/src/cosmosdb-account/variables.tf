variable "cosmosdb_configs" {
  type = list(object({
    resource_key              = string
    resource_group_name       = string
    location                  = string
    name                      = string
    offer_type                = string
    kind                      = string
    enable_automatic_failover = bool
    capabilities              = list(string)
    cmk_encryption_enabled    = bool
    consistency_policy = object({
      consistency_level       = string
      max_interval_in_seconds = number
      max_staleness_prefix    = number
    })
    geo_location = list(object({
      location          = string
      failover_priority = number
      zone_redundant    = bool
    }))
    create_mode                           = string
    default_identity_type                 = string
    ip_range_filter                       = string
    enable_free_tier                      = bool
    public_network_access_enabled         = bool
    is_virtual_network_filter_enabled     = bool
    enable_multiple_write_locations       = bool
    access_key_metadata_writes_enabled    = bool
    mongo_server_version                  = string
    network_acl_bypass_for_azure_services = bool
    network_acl_bypass_ids                = list(string)
    local_authentication_disabled         = bool
    virtual_network_rule = list(object({
      id                                   = string
      ignore_missing_vnet_service_endpoint = bool
    }))
    analytical_storage_enabled = bool
    analytical_storage = object({
      schema_type = string
    })
    capacity = object({
      total_throughput_limit = number
    })
    backup = object({
      type                = string
      interval_in_minutes = number
      retention_in_hours  = number
      storage_redundancy  = string
    })
    cors_rule = object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })
    identity = optional(object(
      {
        type                = string
        user_identity_names = list(string)
      }
    ))
    restore = object({
      source_cosmosdb_account_id = string
      restore_timestamp_in_utc   = string
      database = object({
        name             = string
        collection_names = string
      })
    })
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

variable "app_key_vault_id" {
  type    = string
  default = null
}

variable "admin_key_vault_id" {
  type = string
}