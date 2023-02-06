variable "synapse_configs" {
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
    firewall_rules = optional(list(object(
      {
        name             = string
        start_ip_address = string
        end_ip_address   = string
      }
      )), [{
      name             = "AllowAllWindowsAzureIps"
      start_ip_address = "0.0.0.0"
      end_ip_address   = "0.0.0.0"
    }])
    workspaces = list(object(
      {
        name                                 = string
        resource_group_name                  = optional(string)
        storage_account_name                 = string
        filesystem_name                      = string
        compute_subnet_name                  = optional(string)
        data_exfiltration_protection_enabled = optional(bool)
        linking_allowed_for_aad_tenant_ids   = optional(list(string))
        managed_virtual_network_enabled      = optional(bool)
        public_network_access_enabled        = optional(bool)
        sql_identity_control_enabled         = optional(bool)
        customer_managed_key_name            = optional(string)
        spark_pools = optional(list(object(
          {
            name                                = string
            node_size_family                    = string
            node_size                           = string
            node_count                          = optional(number)
            cache_size                          = optional(number)
            compute_isolation_enabled           = optional(bool)
            dynamic_executor_allocation_enabled = optional(bool)
            min_executors                       = optional(number)
            max_executors                       = optional(number)
            session_level_packages_enabled      = optional(bool)
            spark_log_folder                    = optional(string)
            spark_events_folder                 = optional(string)
            spark_version                       = optional(string)
            auto_pause = optional(object({
              delay_in_minutes = number
            }))
            auto_scale = optional(object({
              min_node_count = number
              max_node_count = number
            }))
            library_requirement = optional(object({
              content   = string
              file_name = string
            }))
            spark_config = optional(object({
              content   = string
              file_name = string
            }))
          }
        )))
        workspace_aad_admin = optional(object(
          {
            login     = string
            object_id = string
          }
        ))
        workspace_role_assignments = optional(list(object(
          {
            role_name  = string
            object_ids = list(string)
          }
        )), [])
        workspace_linked_services = optional(list(object(
          {
            resource_name   = string
            type            = string
            type_properties = map(string)
          }
        )), [])
        identity = optional(object(
          {
            type                = string
            user_identity_names = list(string)
          }
          ), {
          type                = "SystemAssigned"
          user_identity_names = []
        })
        tags = optional(map(string), {})
      }
    ))
  })

  default = null
}

locals {

  synapse_inputs              = var.synapse_configs
  synapse_rgp                 = try(local.synapse_inputs.resource_group_name, null)
  synapse_network_rules       = try(local.synapse_inputs.network_rules, null)
  synapse_diagnostic_settings = try(local.synapse_inputs.diagnostic_settings, null)
  synapse_role_assignments    = try(local.synapse_inputs.role_assignments, [])
  synapse_tags                = try(local.synapse_inputs.tags, {})
  synapse_firewall_rules      = try(local.synapse_inputs.firewall_rules, [])
  synapse_list                = try(local.synapse_inputs.workspaces, [])

  synapse_resource_groups = distinct([
    for synapse in local.synapse_list : {
      name             = coalesce(synapse.resource_group_name, local.synapse_rgp)
      resource_key     = lower(coalesce(synapse.resource_group_name, local.synapse_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])


  synapse_configs_map = {
    for synapse in local.synapse_list : synapse.name => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(synapse.resource_group_name, local.synapse_rgp),
        synapse.name
      ))
      resource_group_name = module.resource_groups.outputs[lower(coalesce(synapse.resource_group_name, local.synapse_rgp))].name
      location            = local.location
      tags = merge(
        local.synapse_tags,
        synapse.tags,
        local.common_resource_tags
      )
      diagnostic_settings = try(length(local.synapse_diagnostic_settings) > 0, false) ? [
        for setting in local.synapse_diagnostic_settings.settings : {
          name   = setting.name
          log    = setting.log
          metric = setting.metric
          log_analytics_workspace_name = try(
            local.synapse_diagnostic_settings.log_analytics_workspace_name,
            null
          )
          log_analytics_workspace_id = try(
            local.synapse_diagnostic_settings.log_analytics_workspace_id,
            # module.log_analytics.outputs[local.synapse_diagnostic_settings.log_analytics_workspace_name].id, ## Needs fixing
            null
          )
        }
      ] : []
      role_assignments                     = local.synapse_role_assignments
      name                                 = synapse.name
      storage_account_id                   = module.storage_accounts.outputs[local.storage_acc_configs_map[synapse.storage_account_name].resource_key].id
      sql_administrator_login              = lower(format("%s-admin", synapse.name))
      sql_administrator_login_password     = random_password.sql_admin_password["sql_admin_password"].result
      filesystem_name                      = synapse.filesystem_name
      compute_subnet_id                    = try(local.subnet_ids_by_name[synapse.compute_subnet_name], null)
      data_exfiltration_protection_enabled = synapse.data_exfiltration_protection_enabled
      linking_allowed_for_aad_tenant_ids   = synapse.linking_allowed_for_aad_tenant_ids
      managed_virtual_network_enabled      = synapse.managed_virtual_network_enabled
      public_network_access_enabled        = synapse.public_network_access_enabled
      sql_identity_control_enabled         = synapse.sql_identity_control_enabled
      customer_managed_key_name            = synapse.customer_managed_key_name
      workspace_aad_admin                  = synapse.workspace_aad_admin
      workspace_role_assignments           = synapse.workspace_role_assignments
      workspace_linked_services = [
        for linked_service in synapse.workspace_linked_services : {
          name                 = lower(format("%s_%s", linked_service.resource_name, linked_service.type))
          type                 = linked_service.type
          type_properties_json = jsonencode(linked_service.type_properties)
          linked_service_id    = lower(linked_service.type) == "azurekeyvault" ? module.keyvault.outputs[local.keyvault_configs_map[linked_service.resource_name].resource_key].id : null
        }
      ]
      firewall_rules = distinct(concat(local.synapse_firewall_rules, [{
        name             = "AllowAllWindowsAzureIps"
        start_ip_address = "0.0.0.0"
        end_ip_address   = "0.0.0.0"
      }]))
      identity    = synapse.identity
      spark_pools = synapse.spark_pools
    }
  }

  synapse_configs = values(local.synapse_configs_map)

  sql_password = {
    sql_admin_password = {
      length      = 16
      lower       = true
      min_lower   = 1
      min_upper   = 2
      min_numeric = 1
      min_special = 1
    }
  }

}

resource "random_password" "sql_admin_password" {
  for_each    = try(length(var.synapse_configs), 0) > 0 ? local.sql_password : {}
  length      = each.value.length
  lower       = each.value.lower
  min_lower   = each.value.min_lower
  min_upper   = each.value.min_upper
  min_numeric = each.value.min_numeric
  min_special = each.value.min_special
}

module "azure_synapse" {
  source             = "./modules/src/synapse"
  synapse_configs    = local.synapse_configs
  app_key_vault_id   = local.infra_keyvault_id
  admin_key_vault_id = local.admin_key_vault_id
}
