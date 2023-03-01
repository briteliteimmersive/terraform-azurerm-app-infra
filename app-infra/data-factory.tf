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
        ), {
        type                = "SystemAssigned" ## Defaulted to use a system assigned identity so linked services can use identity for access.
        user_identity_names = []
      })
      customer_managed_key_user_identity_name = optional(string)
      vsts_configuration = optional(object({
        account_name    = string
        branch_name     = string
        project_name    = string
        repository_name = string
        root_folder     = string
        tenant_id       = string
      }))
      keyvault_linked_services = optional(list(object({
        key_vault_name           = string
        description              = optional(string)
        integration_runtime_name = optional(string)
        annotations              = optional(list(string), [])
        parameters               = optional(map(string))
        additional_properties    = optional(map(string))
      })), [])
      adls_gen2_linked_services = optional(list(object({
        storage_account_name     = string
        description              = optional(string)
        integration_runtime_name = optional(string)
        annotations              = optional(list(string), [])
        parameters               = optional(map(string))
        additional_properties    = optional(map(string))
      })), [])
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
      role_assignments                = local.data_factory_role_assignments
      name                            = data_factory.name
      managed_virtual_network_enabled = data_factory.managed_virtual_network_enabled
      public_network_enabled          = data_factory.public_network_enabled
      identity                        = data_factory.identity
      github_configuration            = data_factory.github_configuration
      global_parameter                = data_factory.global_parameter
      vsts_configuration              = data_factory.vsts_configuration
      customer_managed_key_user_identity_name = lower(data_factory.identity.type) != "systemassigned" ? try(contains(
        data_factory.identity.user_identity_names,
        data_factory.customer_managed_key_user_identity_name
      ), false) ? data_factory.customer_managed_key_user_identity_name : try(data_factory.identity.user_identity_names[0], null) : null
      keyvault_linked_services = [
        for kv_linked_service in data_factory.keyvault_linked_services : {
          name                     = lower(format("%s_keyvault", kv_linked_service.key_vault_name))
          key_vault_name           = kv_linked_service.key_vault_name
          key_vault_id             = module.keyvault.outputs[local.keyvault_configs_map[kv_linked_service.key_vault_name].resource_key].id
          description              = kv_linked_service.description
          integration_runtime_name = kv_linked_service.integration_runtime_name
          annotations              = kv_linked_service.annotations
          parameters               = kv_linked_service.parameters
          additional_properties    = kv_linked_service.additional_properties
        }
      ]
      adls_gen2_linked_services = [
        for adls_gen2_linked_service in data_factory.adls_gen2_linked_services : {
          name                     = lower(format("%s_adls_gen2", adls_gen2_linked_service.storage_account_name))
          storage_account_name     = adls_gen2_linked_service.storage_account_name
          storage_account_id       = module.storage_accounts.outputs[local.storage_acc_configs_map[adls_gen2_linked_service.storage_account_name].resource_key].id
          url                      = module.storage_accounts.outputs[local.storage_acc_configs_map[adls_gen2_linked_service.storage_account_name].resource_key].primary_dfs_endpoint
          description              = adls_gen2_linked_service.description
          integration_runtime_name = adls_gen2_linked_service.integration_runtime_name
          annotations              = adls_gen2_linked_service.annotations
          parameters               = adls_gen2_linked_service.parameters
          additional_properties    = adls_gen2_linked_service.additional_properties
        }
      ]
    }
  }

  data_factory_configs = values(local.data_factory_configs_map)
}

module "data_factory" {
  source               = "./modules/src/data-factory"
  data_factory_configs = local.data_factory_configs
  app_key_vault_id     = local.infra_keyvault_id
  admin_key_vault_id   = local.admin_key_vault_id
}

output "module" {
  value = module.data_factory
}