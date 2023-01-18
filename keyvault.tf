variable "keyvault_configs" {
  type = object({
    resource_group_name = string
    network_rules = optional(object({
      public_ip_ranges = list(string)
      subnet_ids       = list(string)
      }), {
      public_ip_ranges = []
      subnet_ids       = []
    })
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
    keyvaults = list(object(
      {
        name                            = string
        resource_group_name             = optional(string)
        tags                            = optional(map(string), {})
        sku_name                        = optional(string, "premium")
        enabled_for_deployment          = optional(bool)
        enabled_for_disk_encryption     = optional(bool)
        enabled_for_template_deployment = optional(bool)
        purge_protection_enabled        = optional(bool)
        soft_delete_retention_days      = optional(number)
      }
    ))
  })

}

locals {
  keyvault_inputs              = var.keyvault_configs
  keyvault_rgp                 = try(local.keyvault_inputs.resource_group_name, null)
  keyvault_network_rules       = try(local.keyvault_inputs.network_rules, null)
  keyvault_diagnostic_settings = try(local.keyvault_inputs.diagnostic_settings, null)
  keyvault_role_assignments = concat(local.keyvault_inputs.role_assignments, [
    {
      role_definition_id = "00482a5a-887f-4fb3-b363-3b7fe8e74483" ## Keyvault Admin role for SPN
      object_ids         = [local.client_object_id]
    }
  ])
  keyvault_tags = try(local.keyvault_inputs.tags, {})
  keyvault_list = try(local.keyvault_inputs.keyvaults, [])


  keyvault_resource_groups = distinct([
    for keyvault in local.keyvault_list : {
      name             = coalesce(keyvault.resource_group_name, local.keyvault_rgp)
      resource_key     = lower(coalesce(keyvault.resource_group_name, local.keyvault_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])

  keyvault_configs_map = {
    for keyvault in local.keyvault_list : keyvault.name => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(keyvault.resource_group_name, local.keyvault_rgp),
        keyvault.name
      ))
      resource_group_name       = module.resource_groups.outputs[lower(coalesce(keyvault.resource_group_name, local.keyvault_rgp))].name
      location                  = local.location
      enable_rbac_authorization = true
      tags = merge(
        local.keyvault_tags,
        keyvault.tags,
        local.common_resource_tags
      )
      network_acls = {
        default_action = length(local.deployment_agent_subnet_id) > 0 ? "Deny" : "Allow"
        bypass         = "AzureServices"
        ip_rules = distinct(concat(
          local.network_rules.public_ip_ranges,
          local.keyvault_network_rules.public_ip_ranges
        ))
        virtual_network_subnet_ids = distinct(concat(
          local.deployment_agent_subnet_id,
          local.network_rules.subnet_ids,
          local.keyvault_network_rules.subnet_ids,
          [for name, id in local.subnet_ids_by_name : id]
        ))
      }
      diagnostic_settings = try(length(local.keyvault_diagnostic_settings) > 0, false) ? [
        for setting in local.keyvault_diagnostic_settings.settings : {
          name   = setting.name
          log    = setting.log
          metric = setting.metric
          log_analytics_workspace_name = try(
            local.keyvault_diagnostic_settings.log_analytics_workspace_name,
            null
          )
          log_analytics_workspace_id = try(
            local.keyvault_diagnostic_settings.log_analytics_workspace_id,
            # module.log_analytics.outputs[local.keyvault_diagnostic_settings.log_analytics_workspace_name].id, ## Needs fixing
            null
          )
        }
      ] : []
      role_assignments                = local.keyvault_role_assignments
      name                            = keyvault.name
      sku_name                        = keyvault.sku_name
      enabled_for_deployment          = keyvault.enabled_for_deployment
      enabled_for_disk_encryption     = keyvault.enabled_for_disk_encryption
      enabled_for_template_deployment = keyvault.enabled_for_template_deployment
      purge_protection_enabled        = keyvault.purge_protection_enabled
      soft_delete_retention_days      = keyvault.soft_delete_retention_days
    }
  }

  keyvault_configs = values(local.keyvault_configs_map)

  infra_keyvault_name = local.keyvault_list[0].name

  infra_keyvault_id = module.keyvault.outputs[local.keyvault_configs_map[local.infra_keyvault_name].resource_key].id
}

module "keyvault" {
  source           = "./modules/src/key-vault"
  keyvault_configs = local.keyvault_configs
}

output "keyvault" {
  value = module.keyvault.outputs
}