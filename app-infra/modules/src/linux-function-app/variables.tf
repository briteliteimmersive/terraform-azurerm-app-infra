variable "linux_function_app_configs" {
  type = list(
    object({
      resource_key        = string
      name                = string
      location            = string
      resource_group_name = string
      service_plan_id     = string
      app_settings        = map(string)
      tags                = map(string)
      auth_settings = object(
        {
          enabled                        = bool
          additional_login_parameters    = string
          allowed_external_redirect_urls = list(string)
          default_provider               = string
          issuer                         = string
          runtime_version                = string
          token_refresh_extension_hours  = number
          token_store_enabled            = bool
          unauthenticated_client_action  = string
          active_directory = object(
            {
              client_id         = string
              client_secret     = string
              allowed_audiences = string
            }
          )
          facebook = object(
            {
              app_id       = string
              app_secret   = string
              oauth_scopes = string
            }
          )
          github = object({
            app_id       = string
            app_secret   = string
            oauth_scopes = string
          })
          google = object(
            {
              client_id     = string
              client_secret = string
              oauth_scopes  = string
            }
          )
          microsoft = object(
            {
              client_id     = string
              client_secret = string
              oauth_scopes  = string
            }
          )
          twitter = object(
            {
              consumer_key    = string
              consumer_secret = string
            }
          )
        }
      )
      backup = object(
        {
          name                = string
          enabled             = bool
          storage_account_url = string
          schedule = object(
            {
              frequency_interval       = string
              frequency_unit           = string
              keep_at_least_one_backup = bool
              retention_period_days    = number
              start_time               = string
            }
          )
        }
      )
      builtin_logging_enabled    = bool
      client_certificate_enabled = bool
      client_certificate_mode    = string
      connection_string = list(object(
        {
          name  = string
          type  = string
          value = string
        }
      ))
      content_share_force_disabled = bool
      daily_memory_time_quota      = number
      enabled                      = bool
      functions_extension_version  = string
      https_only                   = bool
      identity = object(
        {
          type                = string
          user_identity_names = list(string)
        }
      )
      keyvault_identity_name        = string
      storage_account_id            = string
      storage_account_name          = string
      storage_account_access_key    = string
      storage_uses_managed_identity = string
      storage_key_vault_secret_id   = string
      tags                          = map(string)
      virtual_network_subnet_id     = string
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
      sticky_settings = object({
        app_setting_names       = list(string)
        connection_string_names = list(string)
      })
      site_config = object({
        always_on                              = bool
        api_definition_url                     = string
        api_management_api_id                  = string
        app_command_line                       = string
        app_scale_limit                        = string
        application_insights_connection_string = string
        application_insights_key               = string
        application_stack = object({
          dotnet_version              = string
          use_dotnet_isolated_runtime = string
          java_version                = string
          node_version                = string
          powershell_core_version     = string
          python_version              = string
          use_custom_runtime          = string
          docker = list(object({
            registry_url = string
            image_name   = string
            image_tag    = string
          }))

        })
        app_service_logs = object({
          disk_quota_mb         = number
          retention_period_days = number
        })
        cors = object({
          allowed_origins     = list(string)
          support_credentials = bool
        })
        default_documents                 = list(string)
        elastic_instance_minimum          = number
        ftps_state                        = string
        health_check_path                 = string
        health_check_eviction_time_in_min = string
        http2_enabled                     = bool
        ip_restriction = list(
          object(
            {
              ip_address                = string
              service_tag               = string
              virtual_network_subnet_id = string
              name                      = string
              priority                  = number
              action                    = string
              headers = object(
                {
                  x_azure_fdid      = list(string)
                  x_fd_health_probe = list(string)
                  x_forwarded_for   = list(string)
                  x_forwarded_host  = list(string)
                }
              )
            }
          )
        )
        load_balancing_mode              = string
        managed_pipeline_mode            = string
        minimum_tls_version              = string
        pre_warmed_instance_count        = string
        remote_debugging_enabled         = bool
        remote_debugging_version         = string
        runtime_scale_monitoring_enabled = bool
        scm_ip_restriction = list(
          object(
            {
              ip_address                = string
              service_tag               = string
              virtual_network_subnet_id = string
              name                      = string
              priority                  = number
              action                    = string
              headers = object(
                {
                  x_azure_fdid      = list(string)
                  x_fd_health_probe = list(string)
                  x_forwarded_for   = list(string)
                  x_forwarded_host  = list(string)
                }
              )
            }
          )
        )
        scm_minimum_tls_version                       = string
        scm_use_main_ip_restriction                   = bool
        use_32_bit_worker                             = bool
        vnet_route_all_enabled                        = bool
        websockets_enabled                            = bool
        worker_count                                  = number
        container_registry_use_managed_identity       = bool
        container_registry_managed_identity_client_id = string
      })
    })
  )
}

variable "app_key_vault_id" {
  type    = string
  default = null
}