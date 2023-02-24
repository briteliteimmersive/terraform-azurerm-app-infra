variable "linux_apps_configs" {
  type = object(
    {
      resource_group_name = string
      diagnostic_settings = optional(list(object(
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
      )))
      role_assignments = optional(list(
        object(
          {
            role_definition_id = string
            object_ids         = list(string)
          }
        )
      ), [])
      tags = optional(map(string), {})
      apps = list(object({
        resource_group_name = optional(string)
        ip_restriction = optional(list(
          object(
            {
              ip_address                = optional(string)
              service_tag               = optional(string)
              virtual_network_subnet_id = string
              name                      = string
              priority                  = number
              action                    = optional(string)
              headers = optional(object(
                {
                  x_azure_fdid      = list(string)
                  x_fd_health_probe = list(string)
                  x_forwarded_for   = list(string)
                  x_forwarded_host  = list(string)
                }
              ))
            }
          )
        ), [])
        service_plan = object({
          name                         = string
          sku_name                     = string
          per_site_scaling_enabled     = optional(bool)
          worker_count                 = optional(number)
          zone_balancing_enabled       = optional(bool)
          maximum_elastic_worker_count = optional(number)
          tags                         = optional(map(string), {})
        })
        function_apps = optional(list(
          object(
            {
              name         = string
              app_settings = optional(map(string))
              tags         = optional(map(string), {})
              auth_settings = optional(object(
                {
                  enabled                        = bool
                  additional_login_parameters    = optional(string)
                  allowed_external_redirect_urls = optional(list(string))
                  default_provider               = optional(string)
                  issuer                         = optional(string)
                  runtime_version                = optional(string)
                  token_refresh_extension_hours  = optional(number)
                  token_store_enabled            = optional(bool)
                  unauthenticated_client_action  = optional(string)
                }
              ))
              builtin_logging_enabled      = optional(bool)
              client_certificate_enabled   = optional(bool)
              client_certificate_mode      = optional(string)
              content_share_force_disabled = optional(bool)
              daily_memory_time_quota      = optional(number)
              enabled                      = optional(bool)
              functions_extension_version  = optional(string)
              identity = optional(object(
                {
                  type                = string
                  user_identity_names = optional(list(string), [])
                }
              ))
              keyvault_identity_name        = optional(string)
              storage_account_name          = string
              storage_uses_managed_identity = optional(bool, false)
              subnet_name                   = optional(string)
              sticky_settings = optional(object({
                app_setting_names       = optional(list(string), [])
                connection_string_names = optional(list(string), [])
              }))
              site_config = optional(object({
                always_on                 = optional(bool)
                api_definition_url        = optional(string)
                api_management_api_id     = optional(string)
                app_command_line          = optional(string)
                app_scale_limit           = optional(string)
                application_insights_name = optional(string)
                application_stack = optional(object({
                  dotnet_version              = optional(string)
                  use_dotnet_isolated_runtime = optional(string)
                  java_version                = optional(string)
                  node_version                = optional(string)
                  powershell_core_version     = optional(string)
                  python_version              = optional(string)
                  use_custom_runtime          = optional(string)
                  docker = optional(list(object({
                    registry_url = string
                    image_name   = string
                    image_tag    = string
                  })), [])
                }))
                app_service_logs = optional(object({
                  disk_quota_mb         = optional(number)
                  retention_period_days = optional(number)
                }))
                cors = optional(object({
                  allowed_origins     = list(string)
                  support_credentials = optional(bool)
                }))
                default_documents                 = optional(list(string))
                elastic_instance_minimum          = optional(number)
                ftps_state                        = optional(string)
                health_check_path                 = optional(string)
                health_check_eviction_time_in_min = optional(string)
                http2_enabled                     = optional(bool)
                load_balancing_mode               = optional(string)
                managed_pipeline_mode             = optional(string)
                pre_warmed_instance_count         = optional(string)
                remote_debugging_enabled          = optional(bool)
                remote_debugging_version          = optional(string)
                runtime_scale_monitoring_enabled  = optional(bool)
                scm_use_main_ip_restriction       = optional(bool, true)
                use_32_bit_worker                 = optional(bool)
                vnet_route_all_enabled            = optional(bool)
                websockets_enabled                = optional(bool)
                worker_count                      = optional(number)
                container_registry_name           = optional(string)
                }), {
                always_on                         = true
                api_definition_url                = null
                api_management_api_id             = null
                app_command_line                  = null
                app_scale_limit                   = null
                application_insights_name         = null
                application_stack                 = null
                app_service_logs                  = null
                cors                              = null
                default_documents                 = []
                elastic_instance_minimum          = null
                ftps_state                        = null
                health_check_path                 = null
                health_check_eviction_time_in_min = null
                http2_enabled                     = null
                load_balancing_mode               = null
                managed_pipeline_mode             = null
                pre_warmed_instance_count         = null
                remote_debugging_enabled          = null
                remote_debugging_version          = null
                runtime_scale_monitoring_enabled  = null
                scm_use_main_ip_restriction       = true
                use_32_bit_worker                 = null
                vnet_route_all_enabled            = null
                websockets_enabled                = null
                worker_count                      = null
                container_registry_name           = null
              })
            }
          )
        ), [])
      }))
    }
  )
  default = null
}

locals {

  linux_apps_inputs              = var.linux_apps_configs
  linux_apps_rgp                 = try(local.linux_apps_inputs.resource_group_name, null)
  linux_apps_diagnostic_settings = try(local.linux_apps_inputs.diagnostic_settings, [])
  linux_apps_role_assignments    = try(local.linux_apps_inputs.role_assignments, [])
  linux_apps_tags                = try(local.linux_apps_inputs.tags, {})
  linux_apps_list                = try(local.linux_apps_inputs.apps, [])

  linux_apps_resource_groups = distinct([
    for linux_app in local.linux_apps_list : {
      name             = coalesce(linux_app.resource_group_name, local.linux_apps_rgp)
      resource_key     = lower(coalesce(linux_app.resource_group_name, local.linux_apps_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])

}