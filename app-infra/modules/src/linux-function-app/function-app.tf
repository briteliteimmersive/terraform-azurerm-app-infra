
locals {
  linux_function_app_configs = {
    for function_app_config in var.linux_function_app_configs : function_app_config.resource_key => function_app_config
  }
}

resource "azurerm_linux_function_app" "linux_function_app" {
  for_each                     = local.linux_function_app_configs
  name                         = each.value.name
  resource_group_name          = each.value.resource_group_name
  location                     = each.value.location
  service_plan_id              = each.value.service_plan_id
  builtin_logging_enabled      = each.value.builtin_logging_enabled
  client_certificate_enabled   = each.value.client_certificate_enabled
  client_certificate_mode      = each.value.client_certificate_mode
  content_share_force_disabled = each.value.content_share_force_disabled
  daily_memory_time_quota      = each.value.daily_memory_time_quota
  enabled                      = each.value.enabled
  functions_extension_version  = each.value.functions_extension_version
  https_only                   = each.value.https_only
  storage_account_name         = each.value.storage_account_name
  storage_account_access_key   = each.value.storage_account_access_key
  tags                         = each.value.tags
  app_settings                 = each.value.app_settings
  virtual_network_subnet_id    = each.value.virtual_network_subnet_id

  dynamic "auth_settings" {
    for_each = try(length(each.value.auth_settings), 0) > 0 ? [each.value.auth_settings] : []

    content {
      enabled                        = lookup(auth_settings.value, "enabled", false)
      additional_login_parameters    = lookup(auth_settings.value, "additional_login_parameters", null)
      allowed_external_redirect_urls = lookup(auth_settings.value, "allowed_external_redirect_urls", null)
      default_provider               = lookup(auth_settings.value, "default_provider", null)
      issuer                         = lookup(auth_settings.value, "issuer", null)
      runtime_version                = lookup(auth_settings.value, "runtime_version", null)
      token_refresh_extension_hours  = lookup(auth_settings.value, "token_refresh_extension_hours", null)
      token_store_enabled            = lookup(auth_settings.value, "token_store_enabled", null)
      unauthenticated_client_action  = lookup(auth_settings.value, "unauthenticated_client_action", null)

      dynamic "active_directory" {
        for_each = try(length(auth_settings.value.active_directory), 0) > 0 ? [auth_settings.value.active_directory] : []

        content {
          client_id         = active_directory.value.client_id
          client_secret     = lookup(active_directory.value, "client_secret", null)
          allowed_audiences = lookup(active_directory.value, "allowed_audiences", null)
        }
      }

      dynamic "facebook" {
        for_each = try(length(auth_settings.value.facebook), 0) > 0 ? [auth_settings.value.facebook] : []

        content {
          app_id       = facebook.value.app_id
          app_secret   = facebook.value.app_secret
          oauth_scopes = lookup(facebook.value, "oauth_scopes", null)
        }
      }

      dynamic "google" {
        for_each = try(length(auth_settings.value.google), 0) > 0 ? [auth_settings.value.google] : []

        content {
          client_id     = google.value.client_id
          client_secret = google.value.client_secret
          oauth_scopes  = lookup(google.value, "oauth_scopes", null)
        }
      }

      dynamic "microsoft" {
        for_each = try(length(auth_settings.value.microsoft), 0) > 0 ? [auth_settings.value.microsoft] : []

        content {
          client_id     = microsoft.value.client_id
          client_secret = microsoft.value.client_secret
          oauth_scopes  = lookup(microsoft.value, "oauth_scopes", null)
        }
      }

      dynamic "twitter" {
        for_each = try(length(auth_settings.value.twitter), 0) > 0 ? [auth_settings.value.twitter] : []

        content {
          consumer_key    = twitter.value.consumer_key
          consumer_secret = twitter.value.consumer_secret
        }
      }
    }
  }
  dynamic "backup" {
    for_each = try(length(each.value.backup), 0) > 0 ? [each.value.backup] : []

    content {
      name                = backup.value.name
      enabled             = backup.value.enabled
      storage_account_url = lookup(backup.value, "storage_account_url", null)
      schedule {
        frequency_interval       = backup.value.schedule.frequency_interval
        frequency_unit           = backup.value.schedule.frequency_unit
        keep_at_least_one_backup = lookup(backup.value.schedule, "keep_at_least_one_backup", null)
        retention_period_days    = lookup(backup.value.schedule, "retention_period_days ", null)
        start_time               = lookup(backup.value.schedule, "start_time", null)
      }
    }
  }
  dynamic "connection_string" {
    for_each = try(length(each.value.connection_string), 0) > 0 ? each.value.connection_string : []

    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }
  site_config {
    always_on                                     = each.value.site_config.always_on
    api_definition_url                            = each.value.site_config.api_definition_url
    api_management_api_id                         = each.value.site_config.api_management_api_id
    app_command_line                              = each.value.site_config.app_command_line
    app_scale_limit                               = each.value.site_config.app_scale_limit
    application_insights_connection_string        = each.value.site_config.application_insights_connection_string
    application_insights_key                      = each.value.site_config.application_insights_key
    default_documents                             = each.value.site_config.default_documents
    elastic_instance_minimum                      = each.value.site_config.elastic_instance_minimum
    ftps_state                                    = each.value.site_config.ftps_state
    health_check_path                             = each.value.site_config.health_check_path
    health_check_eviction_time_in_min             = each.value.site_config.health_check_eviction_time_in_min
    http2_enabled                                 = each.value.site_config.http2_enabled
    load_balancing_mode                           = each.value.site_config.load_balancing_mode
    managed_pipeline_mode                         = each.value.site_config.managed_pipeline_mode
    minimum_tls_version                           = each.value.site_config.minimum_tls_version
    pre_warmed_instance_count                     = each.value.site_config.pre_warmed_instance_count
    remote_debugging_enabled                      = each.value.site_config.remote_debugging_enabled
    remote_debugging_version                      = each.value.site_config.remote_debugging_version
    runtime_scale_monitoring_enabled              = each.value.site_config.runtime_scale_monitoring_enabled
    scm_minimum_tls_version                       = each.value.site_config.scm_minimum_tls_version
    scm_use_main_ip_restriction                   = each.value.site_config.scm_use_main_ip_restriction
    use_32_bit_worker                             = each.value.site_config.use_32_bit_worker
    vnet_route_all_enabled                        = each.value.site_config.vnet_route_all_enabled
    websockets_enabled                            = each.value.site_config.websockets_enabled
    worker_count                                  = each.value.site_config.worker_count
    container_registry_use_managed_identity       = each.value.site_config.container_registry_use_managed_identity
    container_registry_managed_identity_client_id = each.value.site_config.container_registry_managed_identity_client_id
    dynamic "application_stack" {
      for_each = try(length(each.value.site_config.application_stack), 0) > 0 ? [each.value.site_config.application_stack] : []
      content {
        dotnet_version              = application_stack.value.dotnet_version
        use_dotnet_isolated_runtime = application_stack.value.use_dotnet_isolated_runtime
        java_version                = application_stack.value.java_version
        node_version                = application_stack.value.node_version
        powershell_core_version     = application_stack.value.powershell_core_version
        python_version              = application_stack.value.python_version
        use_custom_runtime          = application_stack.value.use_custom_runtime
        dynamic "docker" {
          for_each = application_stack.value.docker != null ? application_stack.value.docker : []
          content {
            registry_url = docker.value.registry_url
            image_name   = docker.value.image_name
            image_tag    = docker.value.image_tag
          }
        }
      }
    }
    dynamic "app_service_logs" {
      for_each = try(length(each.value.site_config.app_service_logs), 0) > 0 ? [each.value.site_config.app_service_logs] : []
      content {
        disk_quota_mb         = app_service_logs.value.disk_quota_mb
        retention_period_days = lookup(app_service_logs.value, "retention_period_days", null)

      }
    }
    dynamic "cors" {
      for_each = try(length(each.value.site_config.cors), 0) > 0 ? [each.value.site_config.cors] : []
      content {
        allowed_origins     = lookup(cors.value, "allowed_origins", null)
        support_credentials = lookup(cors.value, "support_credentials", null)
      }

    }
    dynamic "ip_restriction" {
      for_each = try(length(each.value.site_config.ip_restriction), 0) > 0 ? each.value.site_config.ip_restriction : []

      content {
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        service_tag               = lookup(ip_restriction.value, "service_tag", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "virtual_network_subnet_id", null)
        name                      = lookup(ip_restriction.value, "name", null)
        priority                  = lookup(ip_restriction.value, "priority", null)
        action                    = lookup(ip_restriction.value, "action", null)
        dynamic "headers" {
          for_each = try(length(ip_restriction.value.headers), 0) > 0 ? [ip_restriction.value.headers] : []

          content {
            x_azure_fdid      = lookup(headers.value, "x_azure_fdid", null)
            x_fd_health_probe = lookup(headers.value, "x_fd_health_probe", null)
            x_forwarded_for   = lookup(headers.value, "x_forwarded_for", null)
            x_forwarded_host  = lookup(headers.value, "x_forwarded_host", null)
          }
        }
      }
    }
    dynamic "scm_ip_restriction" {
      for_each = try(length(each.value.site_config.scm_ip_restriction), 0) > 0 ? each.value.site_config.scm_ip_restriction : []

      content {
        ip_address                = lookup(scm_ip_restriction.value, "ip_address", null)
        service_tag               = lookup(scm_ip_restriction.value, "service_tag", null)
        virtual_network_subnet_id = lookup(scm_ip_restriction.value, "virtual_network_subnet_id", null)
        name                      = lookup(scm_ip_restriction.value, "name", null)
        priority                  = lookup(scm_ip_restriction.value, "priority", null)
        action                    = lookup(scm_ip_restriction.value, "action", null)
        dynamic "headers" {
          for_each = try(length(scm_ip_restriction.value.headers), 0) > 0 ? [scm_ip_restriction.value.headers] : []

          content {
            x_azure_fdid      = lookup(headers.value, "x_azure_fdid", null)
            x_fd_health_probe = lookup(headers.value, "x_fd_health_probe", null)
            x_forwarded_for   = lookup(headers.value, "x_forwarded_for", null)
            x_forwarded_host  = lookup(headers.value, "x_forwarded_host", null)
          }
        }
      }
    }
  }

  dynamic "identity" {
    for_each = try(length(each.value.identity), 0) > 0 ? [each.value.identity] : []

    content {
      type = identity.value.type
      identity_ids = lower(identity.value.type) == "userassigned" ? flatten([
        for identity in each.value.identity.user_identity_names : [
          azurerm_user_assigned_identity.function_apps_identities[lower(format("%s/%s", each.key, identity))].id
        ]
      ]) : null
    }
  }

  key_vault_reference_identity_id = each.value.keyvault_identity_name != null ? azurerm_user_assigned_identity.function_apps_identities["${each.key}_${each.value.keyvault_identity_name}"].id : null

  dynamic "sticky_settings" {
    for_each = try(length(each.value.sticky_settings), 0) > 0 ? [each.value.sticky_settings] : []

    content {
      app_setting_names       = sticky_settings.value.app_setting_names
      connection_string_names = sticky_settings.value.connection_string_names
    }
  }
  lifecycle {
    ignore_changes = [
      app_settings,
      site_config,
      connection_string
    ]
  }
}