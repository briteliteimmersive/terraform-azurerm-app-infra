variable "cosmosdb_configs" {
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
      subnet_ids       = list(string)
      }), {
      public_ip_ranges = []
      subnet_ids       = []
    })
    cosmosdb = list(object(
      {
        name                      = string
        resource_group_name       = optional(string)
        tags                      = optional(map(string))
        offer_type                = optional(string, "Standard")
        kind                      = optional(string)
        enable_automatic_failover = optional(bool)
        capabilities              = optional(list(string))
        cmk_encryption_enabled    = optional(bool, true)
        consistency_policy = object({
          consistency_level       = string
          max_interval_in_seconds = number
          max_staleness_prefix    = number
        })
        geo_location = optional(list(object({
          location          = string
          failover_priority = number
          zone_redundant    = bool
        })))
        default_identity_type                 = optional(string)
        enable_free_tier                      = optional(bool)
        public_network_access_enabled         = optional(bool)
        is_virtual_network_filter_enabled     = optional(bool, true)
        enable_multiple_write_locations       = optional(bool)
        access_key_metadata_writes_enabled    = optional(bool)
        mongo_server_version                  = optional(string)
        network_acl_bypass_for_azure_services = optional(bool, true)
        network_acl_bypass_ids                = optional(list(string))
        local_authentication_disabled         = optional(bool)
        analytical_storage_enabled            = optional(bool)
        analytical_storage = optional(object({
          schema_type = string
        }))
        capacity = optional(object({
          total_throughput_limit = number
        }))
        backup = optional(object({
          type                = string
          interval_in_minutes = optional(number)
          retention_in_hours  = optional(number)
          storage_redundancy  = optional(string)
        }))
        cors_rule = optional(object({
          allowed_headers    = list(string)
          allowed_methods    = list(string)
          allowed_origins    = list(string)
          exposed_headers    = list(string)
          max_age_in_seconds = number
        }))
        identity = optional(object(
          {
            type                = string
            user_identity_names = optional(list(string))
          }
        ))
        mongodb_databases = optional(list(
          object(
            {
              name       = string
              throughput = optional(number)
              autoscale_settings = optional(object({
                max_throughput = number
              }))
              collections = list(object({
                name                   = string
                shard_key              = optional(string)
                analytical_storage_ttl = optional(number)
                default_ttl_seconds    = optional(number)
                throughput             = optional(number)
                index = optional(list(object(
                  {
                    keys   = list(string)
                    unique = optional(bool)
                  }
                )))
                autoscale_settings = optional(object({
                  max_throughput = number
                }))
              }))
            }
          )
        ), [])
      }
    ))
  })

  default = null
}

locals {

  cosmosdb_inputs              = var.cosmosdb_configs
  cosmosdb_rgp                 = try(local.cosmosdb_inputs.resource_group_name, null)
  cosmosdb_network_rules       = try(local.cosmosdb_inputs.network_rules, null)
  cosmosdb_diagnostic_settings = try(local.cosmosdb_inputs.diagnostic_settings, null)
  cosmosdb_role_assignments    = try(local.cosmosdb_inputs.role_assignments, [])
  cosmosdb_tags                = try(local.cosmosdb_inputs.tags, {})
  cosmosdb_list                = try(local.cosmosdb_inputs.cosmosdb, [])

  cosmosdb_resource_groups = distinct([
    for cosmosdb in local.cosmosdb_list : {
      name             = coalesce(cosmosdb.resource_group_name, local.cosmosdb_rgp)
      resource_key     = lower(coalesce(cosmosdb.resource_group_name, local.cosmosdb_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])


  cosmosdb_configs_map = {
    for cosmosdb in local.cosmosdb_list : cosmosdb.name => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(cosmosdb.resource_group_name, local.cosmosdb_rgp),
        cosmosdb.name
      ))
      resource_group_name = module.resource_groups.outputs[lower(coalesce(cosmosdb.resource_group_name, local.cosmosdb_rgp))].name
      location            = local.location
      tags = merge(
        local.cosmosdb_tags,
        cosmosdb.tags,
        local.common_resource_tags
      )
      virtual_network_rule = [
        for subnet_id in concat(
          local.deployment_agent_subnet_id,
          local.network_rules.subnet_ids,
          local.cosmosdb_network_rules.subnet_ids,
          [for name, id in local.subnet_ids_by_name : id]
          ) : {
          id                                   = subnet_id
          ignore_missing_vnet_service_endpoint = false
        }
      ]
      ip_range_filter = join(",", distinct(
        concat(
          local.network_rules.public_ip_ranges,
          local.cosmosdb_network_rules.public_ip_ranges,
          ["0.0.0.0"]
        )
      ))
      diagnostic_settings = try(length(local.cosmosdb_diagnostic_settings) > 0, false) ? [
        for setting in local.cosmosdb_diagnostic_settings.settings : {
          name   = setting.name
          log    = setting.log
          metric = setting.metric
          log_analytics_workspace_name = try(
            local.cosmosdb_diagnostic_settings.log_analytics_workspace_name,
            null
          )
          log_analytics_workspace_id = try(
            local.cosmosdb_diagnostic_settings.log_analytics_workspace_id,
            # module.log_analytics.outputs[local.cosmosdb_diagnostic_settings.log_analytics_workspace_name].id, ## Needs fixing
            null
          )
        }
      ] : []
      role_assignments           = local.cosmosdb_role_assignments
      name                       = cosmosdb.name
      offer_type                 = cosmosdb.offer_type
      analytical_storage         = cosmosdb.analytical_storage
      analytical_storage_enabled = cosmosdb.analytical_storage_enabled
      capacity                   = cosmosdb.capacity
      ## create_mode only works when backup.type is Continuous
      create_mode           = null
      default_identity_type = cosmosdb.default_identity_type
      kind                  = cosmosdb.kind
      consistency_policy    = cosmosdb.consistency_policy
      geo_location = coalesce(cosmosdb.geo_location, [
        {
          location          = local.location
          failover_priority = 0
          zone_redundant    = false
        }
      ])
      enable_free_tier                      = cosmosdb.enable_free_tier
      enable_automatic_failover             = cosmosdb.enable_automatic_failover
      public_network_access_enabled         = cosmosdb.public_network_access_enabled
      capabilities                          = cosmosdb.capabilities
      is_virtual_network_filter_enabled     = cosmosdb.is_virtual_network_filter_enabled
      enable_multiple_write_locations       = cosmosdb.enable_multiple_write_locations
      access_key_metadata_writes_enabled    = cosmosdb.access_key_metadata_writes_enabled
      mongo_server_version                  = lower(cosmosdb.kind) == "mongodb" ? cosmosdb.mongo_server_version : null
      network_acl_bypass_for_azure_services = cosmosdb.network_acl_bypass_for_azure_services
      local_authentication_disabled         = cosmosdb.local_authentication_disabled
      backup                                = cosmosdb.backup
      cors_rule                             = cosmosdb.cors_rule
      identity                              = cosmosdb.identity
      mongodb_databases                     = cosmosdb.mongodb_databases
      cmk_encryption_enabled                = cosmosdb.cmk_encryption_enabled
      ## TODO
      network_acl_bypass_ids = null
      restore                = null
    }
  }

  cosmosdb_configs = values(local.cosmosdb_configs_map)

  cosmosdb_mongodb_configs = flatten([
    for cosmosdb_key, cosmosdb_config in local.cosmosdb_configs_map : [
      for mongodb in cosmosdb_config.mongodb_databases : merge(mongodb, {
        resource_key        = lower(format("%s/%s", cosmosdb_key, mongodb.name))
        account_name        = module.cosmosdb.outputs[cosmosdb_config.resource_key].name
        resource_group_name = module.cosmosdb.outputs[cosmosdb_config.resource_key].resource_group_name
      })
    ]
  ])
}

module "cosmosdb" {
  source             = "./modules/src/cosmosdb-account"
  cosmosdb_configs   = local.cosmosdb_configs
  app_key_vault_id   = local.infra_keyvault_id
  admin_key_vault_id = local.admin_key_vault_id
}

module "cosmosdb_mongodb" {
  source                   = "./modules/src/cosmosdb-mongodb"
  cosmosdb_mongodb_configs = local.cosmosdb_mongodb_configs
}
