locals {
  ## Linux Function Apps
  linux_function_app_configs = flatten([
    for app_service_config in local.linux_apps_list : [
      for function in app_service_config.function_apps : [
        {
          resource_key = lower(format(
            "%s/%s",
            coalesce(app_service_config.resource_group_name, local.linux_apps_rgp),
            function.name
          ))
          resource_group_name           = module.resource_groups.outputs[coalesce(app_service_config.resource_group_name, local.linux_apps_rgp)].name
          location                      = local.location
          tags                          = merge(function.tags, local.common_resource_tags)
          name                          = function.name
          service_plan_id               = module.service_plan.outputs[local.service_plan_configs_map[app_service_config.service_plan.name].resource_key].id
          app_settings                  = function.app_settings
          builtin_logging_enabled       = function.builtin_logging_enabled
          client_certificate_enabled    = function.client_certificate_enabled
          client_certificate_mode       = function.client_certificate_mode
          sticky_settings               = function.sticky_settings
          content_share_force_disabled  = function.content_share_force_disabled
          daily_memory_time_quota       = function.daily_memory_time_quota
          enabled                       = function.enabled
          functions_extension_version   = function.functions_extension_version
          https_only                    = true
          identity                      = function.identity
          keyvault_identity_name        = function.keyvault_identity_name
          storage_account_name          = module.storage_accounts.outputs[local.storage_acc_configs_map[function.storage_account_name].resource_key].name
          storage_uses_managed_identity = function.storage_uses_managed_identity
          ## If storage uses managed identity then required for role assignment
          storage_account_id = function.storage_uses_managed_identity ? module.storage_accounts.outputs[local.storage_acc_configs_map[function.storage_account_name].resource_key].id : null
          ## If storage uses managed identity, then storage account key not required
          storage_account_access_key = function.storage_uses_managed_identity ? null : module.storage_accounts.sensitive_outputs[local.storage_acc_configs_map[function.storage_account_name].resource_key].primary_access_key
          virtual_network_subnet_id  = try(local.subnet_ids_by_name[function.subnet_name], null)
          role_assignments           = local.linux_apps_role_assignments
          ## TODO: For furture updates
          site_config = merge(function.site_config, {
            application_insights_connection_string = null
            application_insights_key               = null
            ## Force using container registry
            container_registry_use_managed_identity       = true
            container_registry_managed_identity_client_id = null
            ip_restriction                                = app_service_config.ip_restriction
            scm_ip_restriction                            = null
            minimum_tls_version                           = "1.2"
            scm_minimum_tls_version                       = "1.2"
          })
          connection_string           = null
          storage_key_vault_secret_id = null
          backup                      = null
          auth_settings               = null
          diagnostic_settings         = null
        }
      ]
    ]
  ])

  linux_function_app_configs_map = {
    for function_app in local.linux_function_app_configs : function_app.resource_key => function_app
  }

}

module "linux_function_app" {
  source                     = "./modules/src/linux-function-app"
  linux_function_app_configs = local.linux_function_app_configs
  app_key_vault_id           = local.infra_keyvault_id
}
