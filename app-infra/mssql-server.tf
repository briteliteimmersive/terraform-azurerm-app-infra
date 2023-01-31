variable "mssql_server_configs" {
  type = object({
    resource_group_name = string
    network_rules = optional(object({
      public_ip_ranges = list(string)
      subnet_ids       = list(string)
      }), {
      public_ip_ranges = []
      subnet_ids       = []
    })
    firewall_rules = optional(list(object(
      {
        name             = string
        start_ip_address = string
        end_ip_address   = string
      }
    )), [])
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
    servers = list(object(
      {
        name                       = string
        resource_group_name        = optional(string)
        version                    = optional(string, "12.0")
        primary_user_identity_name = optional(string)
        azuread_administrator = optional(object(
          {
            login_username              = string
            object_id                   = string
            azuread_authentication_only = optional(bool, false)
          }
        ))
        connection_policy = optional(string)
        identity = optional(object(
          {
            type                = string
            user_identity_names = optional(list(string), [])
          }
        ))
        databases = optional(list(object(
          {
            name                        = string
            sku_name                    = string
            max_size_gb                 = optional(number)
            auto_pause_delay_in_minutes = optional(number)
            collation                   = optional(string)
            geo_backup_enabled          = optional(bool)
            license_type                = optional(string)
            read_replica_count          = optional(number)
            storage_account_type        = optional(string)
            elastic_pool_name           = optional(string)
            short_term_retention_policy = optional(object(
              {
                backup_interval_in_hours = number
                retention_days           = number
              }
              ), {
              backup_interval_in_hours = 12
              retention_days           = 10
            })
            long_term_retention_policy = optional(object(
              {
                monthly_retention = string
                weekly_retention  = string
                yearly_retention  = string
                week_of_year      = number
              }
              ), {
              monthly_retention = "P10D"
              weekly_retention  = "P1W"
              yearly_retention  = "P1Y"
              week_of_year      = 26
            })
            threat_detection_policy = optional(object(
              {
                state                      = string
                disabled_alerts            = string
                email_account_admins       = string
                email_addresses            = string
                retention_days             = number
                storage_account_access_key = string
                storage_endpoint           = string
              }
            ))
            zone_redundant = optional(bool)
            min_capacity   = optional(number)
          }
        )))
        elastic_pools = optional(list(object(
          {
            name                           = string
            license_type                   = optional(string)
            max_size_gb                    = optional(number)
            max_size_bytes                 = optional(number)
            maintenance_configuration_name = optional(string)
            zone_redundant                 = optional(bool)
            sku = object({
              name     = string
              tier     = string
              family   = optional(string)
              capacity = number
            })
            per_database_settings = object({
              min_capacity = number
              max_capacity = number
            })
          }
        )))
        tags = optional(map(string), {})
      }
    ))
  })

  default = null
}


locals {

  mssql_server_inputs              = var.mssql_server_configs
  mssql_server_rgp                 = try(local.mssql_server_inputs.resource_group_name, null)
  mssql_server_network_rules       = try(local.mssql_server_inputs.network_rules, null)
  mssql_server_firewall_rules      = try(local.mssql_server_inputs.firewall_rules, [])
  mssql_server_diagnostic_settings = try(local.mssql_server_inputs.diagnostic_settings, null)
  mssql_server_role_assignments    = try(local.mssql_server_inputs.role_assignments, [])
  mssql_server_tags                = try(local.mssql_server_inputs.tags, {})
  mssql_server_list                = try(local.mssql_server_inputs.servers, [])


  mssql_server_resource_groups = distinct([
    for mssql_server in local.mssql_server_list : {
      name             = coalesce(mssql_server.resource_group_name, local.mssql_server_rgp)
      resource_key     = lower(coalesce(mssql_server.resource_group_name, local.mssql_server_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])

  mssql_server_configs_map = {
    for mssql_server in local.mssql_server_list : mssql_server.name => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(mssql_server.resource_group_name, local.mssql_server_rgp),
        mssql_server.name
      ))
      resource_group_name = module.resource_groups.outputs[lower(coalesce(mssql_server.resource_group_name, local.mssql_server_rgp))].name
      location            = local.location
      tags = merge(
        local.mssql_server_tags,
        mssql_server.tags,
        local.common_resource_tags
      )
      virtual_network_rules = [
        for name, id in distinct(concat(
          local.deployment_agent_subnet_id,
          local.network_rules.subnet_ids,
          local.mssql_server_network_rules.subnet_ids,
          [for name, id in local.subnet_ids_by_name : id],
          )) : {
          name      = upper(format("ALLOW-%s", basename(id)))
          subnet_id = id
        }
      ]
      firewall_rules = distinct(concat(local.mssql_server_firewall_rules, [
        for key, ip_range in distinct(concat(
          ["0.0.0.0"],
          local.network_rules.public_ip_ranges,
          local.mssql_server_network_rules.public_ip_ranges
          )) : {
          name             = format("FW_RULE_%02d", key)
          start_ip_address = trimsuffix(ip_range, "/32")
          end_ip_address   = trimsuffix(ip_range, "/32")
        } if basename(ip_range) == "32"
      ]))
      diagnostic_settings = try(length(local.mssql_server_diagnostic_settings) > 0, false) ? [
        for setting in local.mssql_server_diagnostic_settings.settings : {
          name   = setting.name
          log    = setting.log
          metric = setting.metric
          log_analytics_workspace_name = try(
            local.mssql_server_diagnostic_settings.log_analytics_workspace_name,
            null
          )
          log_analytics_workspace_id = try(
            local.mssql_server_diagnostic_settings.log_analytics_workspace_id,
            # module.log_analytics.outputs[local.mssql_server_diagnostic_settings.log_analytics_workspace_name].id, ## Needs fixing
            null
          )
        }
      ] : []
      role_assignments             = local.mssql_server_role_assignments
      name                         = mssql_server.name
      version                      = mssql_server.version
      administrator_login          = lower(format("%s-admin", mssql_server.name))
      administrator_login_password = random_password.sql_server_password["sql_server_password"].result
      azuread_administrator        = mssql_server.azuread_administrator
      connection_policy            = mssql_server.connection_policy
      identity                     = mssql_server.identity
      minimum_tls_version          = "1.2"
      primary_user_identity_name   = mssql_server.primary_user_identity_name
      databases                    = mssql_server.databases
      elastic_pools                = mssql_server.elastic_pools
    }
  }

  mssql_server_configs = values(local.mssql_server_configs_map)

  sql_server_password_policy = {
    length      = 16
    lower       = true
    min_lower   = 1
    min_upper   = 2
    min_numeric = 1
    min_special = 1
  }

  sql_server_passwords = {
    sql_server_password = {
      length      = local.sql_server_password_policy.length
      lower       = local.sql_server_password_policy.lower
      min_lower   = local.sql_server_password_policy.min_lower
      min_upper   = local.sql_server_password_policy.min_upper
      min_numeric = local.sql_server_password_policy.min_numeric
      min_special = local.sql_server_password_policy.min_special
    }
  }
}

resource "random_password" "sql_server_password" {
  for_each    = try(length(var.mssql_server_configs), 0) > 0 ? local.sql_server_passwords : {}
  length      = each.value.length
  lower       = each.value.lower
  min_lower   = each.value.min_lower
  min_upper   = each.value.min_upper
  min_numeric = each.value.min_numeric
  min_special = each.value.min_special
}

module "mssql_server" {
  source               = "./modules/src/mssql-server"
  mssql_server_configs = local.mssql_server_configs
  app_key_vault_id     = local.infra_keyvault_id
}

output "mssql_servers" {
  value = module.mssql_server.outputs
}