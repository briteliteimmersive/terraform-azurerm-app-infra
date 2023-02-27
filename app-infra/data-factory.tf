variable "data_factory_configs" {
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
    data_factories = list(object({
      name                            = string
      resource_group_name             = optional(string)
      managed_virtual_network_enabled = optional(bool)
      public_network_enabled          = optional(bool)
      github_configuration = optional(object({
        account_name    = string
        branch_name     = string
        git_url         = string
        repository_name = string
        root_folder     = string
      }))
      global_parameter = optional(list(object({
        name  = string
        type  = string
        value = string
      })), [])
      identity = optional(object(
        {
          type                = string
          user_identity_names = optional(list(string))
        }
      ))
      vsts_configuration = optional(object({
        account_name    = string
        branch_name     = string
        project_name    = string
        repository_name = string
        root_folder     = string
        tenant_id       = string
      }))
      tags = optional(map(string), {})
    }))
  })

  default = null
}

locals {

  data_factory_inputs              = var.data_factory_configs
  data_factory_rgp                 = try(local.data_factory_inputs.resource_group_name, null)
  data_factory_diagnostic_settings = try(local.data_factory_inputs.diagnostic_settings, [])
  data_factory_role_assignments    = try(local.data_factory_inputs.role_assignments, [])
  data_factory_tags                = try(local.data_factory_inputs.tags, {})
  data_factory_list                = try(local.data_factory_inputs.data_factories, [])

  data_factory_resource_groups = distinct([
    for data_factory in local.data_factory_list : {
      name             = coalesce(data_factory.resource_group_name, local.data_factory_rgp)
      resource_key     = lower(coalesce(data_factory.resource_group_name, local.data_factory_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])

  data_factory_configs_map = {
    for data_factory in local.data_factory_list : data_factory.name => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(data_factory.resource_group_name, local.data_factory_rgp),
        data_factory.name
      ))
      resource_group_name = module.resource_groups.outputs[lower(coalesce(data_factory.resource_group_name, local.data_factory_rgp))].name
      location            = local.location
      tags = merge(
        local.data_factory_tags,
        data_factory.tags,
        local.common_resource_tags
      )
      role_assignments                 = local.data_factory_role_assignments
      name                             = data_factory.name
      managed_virtual_network_enabled  = data_factory.managed_virtual_network_enabled
      public_network_enabled           = data_factory.public_network_enabled
      identity                         = data_factory.identity
      github_configuration             = data_factory.github_configuration
      global_parameter                 = data_factory.global_parameter
      vsts_configuration               = data_factory.vsts_configuration
      customer_managed_key_id          = null
      customer_managed_key_identity_id = null
    }
  }

  data_factory_configs = values(local.data_factory_configs_map)
}

module "data_factory" {
  source               = "./modules/src/data-factory"
  data_factory_configs = local.data_factory_configs
  app_key_vault_id     = local.infra_keyvault_id
}

output "module" {
  value = module.data_factory
}