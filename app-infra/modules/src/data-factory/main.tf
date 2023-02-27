locals {
  data_factory_configs = {
    for data_factory_config in var.data_factory_configs : data_factory_config.resource_key => data_factory_config
  }
}

resource "azurerm_data_factory" "data_factory" {
  for_each = local.data_factory_configs

  name                             = each.value.name
  location                         = each.value.location
  resource_group_name              = each.value.resource_group_name
  managed_virtual_network_enabled  = each.value.managed_virtual_network_enabled
  public_network_enabled           = each.value.public_network_enabled
  customer_managed_key_id          = each.value.customer_managed_key_id
  customer_managed_key_identity_id = each.value.customer_managed_key_identity_id
  tags                             = each.value.tags

  dynamic "github_configuration" {
    for_each = try(length(each.value.github_configuration), 0) > 0 ? [each.value.github_configuration] : []

    content {
      account_name    = lookup(github_configuration.value, "account_name", null)
      branch_name     = lookup(github_configuration.value, "branch_name", null)
      git_url         = lookup(github_configuration.value, "git_url", null)
      repository_name = lookup(github_configuration.value, "repository_name", null)
      root_folder     = lookup(github_configuration.value, "root_folder", null)
    }
  }

  dynamic "global_parameter" {
    for_each = try(length(each.value.global_parameter), 0) > 0 ? each.value.global_parameter : []

    content {
      name  = global_parameter.value.name  ##lookup(global_parameter.value, "name", null)
      type  = global_parameter.value.type  ##lookup(global_parameter.value, "type", null)
      value = global_parameter.value.value ##lookup(global_parameter.value, "value", null)
    }
  }

  dynamic "identity" {
    for_each = try(length(each.value.identity), 0) > 0 ? [each.value.identity] : []

    content {
      type = identity.value.type
      identity_ids = lower(identity.value.type) == "userassigned" ? flatten([
        for identity in each.value.identity.user_identity_names : [
          azurerm_user_assigned_identity.data_factory_identities["${each.key}_${identity}"].id
        ]
      ]) : null
    }
  }
  dynamic "vsts_configuration" {
    for_each = try(length(each.value.vsts_configuration), 0) > 0 ? [each.value.vsts_configuration] : []

    content {
      account_name    = lookup(vsts_configuration.value, "account_name", null)
      branch_name     = lookup(vsts_configuration.value, "branch_name", null)
      project_name    = lookup(vsts_configuration.value, "project_name", null)
      repository_name = lookup(vsts_configuration.value, "repository_name", null)
      root_folder     = lookup(vsts_configuration.value, "root_folder", null)
      tenant_id       = lookup(vsts_configuration.value, "tenant_id", null)
    }
  }

}


# ##Initialize azurerm_data_factory_integration_runtime_azure
# locals {
#   azure_runtime = [
#     for azure_runtime_k, azure_runtime_v in local.data_factory_configs : azure_runtime_v.data_factory_integration_runtime if azure_runtime_v.data_factory_integration_runtime != null
#   ]
# }

# resource "azurerm_data_factory_integration_runtime_azure" "integration_runtime_azure" {
#   for_each = try(length(local.azure_runtime), 0) > 0 ? local.data_factory_configs : {}

#   name                    = lookup(each.value.data_factory_integration_runtime, "name", null)
#   data_factory_id         = azurerm_data_factory.data_factory[each.key].id
#   location                = each.value.location
#   description             = lookup(each.value.data_factory_integration_runtime, "description", null)
#   cleanup_enabled         = lookup(each.value.data_factory_integration_runtime, "cleanup_enabled", false)
#   compute_type            = lookup(each.value.data_factory_integration_runtime, "compute_type", null)
#   core_count              = lookup(each.value.data_factory_integration_runtime, "core_count", null)
#   time_to_live_min        = lookup(each.value.data_factory_integration_runtime, "time_to_live_min", null)
#   virtual_network_enabled = lookup(each.value.data_factory_integration_runtime, "virtual_network_enabled", false)
# }


# ##Initialize azurerm_data_factory_integration_runtime_self_hosted
# locals {
#   self_hosted_runtime = [
#     for self_hosted_runtime_k, self_hosted_runtime_v in local.data_factory_configs : self_hosted_runtime_v.data_factory_integration_runtime_self_hosted if self_hosted_runtime_v.data_factory_integration_runtime_self_hosted != null
#   ]
# }

# resource "azurerm_data_factory_integration_runtime_self_hosted" "integration_runtime_self_hosted" {
#   for_each = try(length(local.self_hosted_runtime), 0) > 0 ? local.data_factory_configs : {}

#   name            = lookup(each.value.data_factory_integration_runtime_self_hosted, "name", null)
#   data_factory_id = azurerm_data_factory.data_factory[each.key].id
#   description     = lookup(each.value.data_factory_integration_runtime_self_hosted, "description", null)

#   dynamic "rbac_authorization" {
#     for_each = try(length(each.value.rbac_authorization), 0) > 0 ? [each.value.rbac_authorization] : []

#     content {
#       resource_id = rbac_authorization.value.resource_id
#     }
#   }
# }

# ##Initialize azurerm_data_factory_managed_private_endpoint
# locals {
#   adf_private_endpoint_configs = flatten([
#     for key, value in local.data_factory_configs : [
#       for pe_k, pe_v in coalesce(value.data_factory_managed_private_endpoint, []) :
#       merge(pe_v, {
#         adf_key = "${value.resource_group_name}-${value.name}"
#       })
#     ]
#   ])
#   adf_private_endpoint_config_map = {
#     for private_endpoint in local.adf_private_endpoint_configs : private_endpoint.name => private_endpoint
#   }
# }

# resource "azurerm_data_factory_managed_private_endpoint" "adf_private_endpoint" {
#   for_each = try(length(local.adf_private_endpoint_config_map), 0) > 0 ? local.adf_private_endpoint_config_map : {}

#   name               = each.value.name
#   data_factory_id    = azurerm_data_factory.data_factory[each.value.adf_key].id
#   target_resource_id = each.value.target_resource_id
#   subresource_name   = lookup(each.value, "subresource_name", null)
#   fqdns              = lookup(each.value, "fqdns", null)
# }

# ##Initialize azurerm_data_factory_linked_service_key_vault
# locals {
#   adf_linked_kv_configs = flatten([
#     for data_factory_config in local.data_factory_configs : [
#       for data_factory_linked_service in coalesce(data_factory_config.data_factory_linked_service_key_vault, []) :
#       merge(data_factory_linked_service, {
#         adf_key = "${data_factory_config.resource_group_name}-${data_factory_config.name}"
#         #        key_vault_id = var.key_vaults[data_factory_linked_service.name].id
#       })
#     ]
#   ])
#   adf_linked_kv_config_map = {
#     for kv in local.adf_linked_kv_configs : kv.adf_key => kv
#   }
# }

# resource "azurerm_data_factory_linked_service_key_vault" "adf_linked_key_vault" {
#   for_each = try(length(local.adf_linked_kv_config_map), 0) > 0 ? local.adf_linked_kv_config_map : {}

#   name                     = each.value.name
#   data_factory_id          = azurerm_data_factory.data_factory[each.key].id
#   key_vault_id             = var.key_vaults[each.value.name].id
#   description              = lookup(each.value, "description", null)
#   integration_runtime_name = lookup(each.value, "integration_runtime_name", null)
#   annotations              = lookup(each.value, "annotations", null)
#   parameters               = lookup(each.value, "parameters", null)
#   additional_properties    = lookup(each.value, "additional_properties", null)
# }

# # resource "azurerm_data_factory_integration_runtime_azure_ssis" "integration_runtime_ssis" {
# #   for_each = local.data_factory_configs

# #   name                                = lookup(each.value.data_factory_integration_runtime_azure_ssis, "name", null)
# #   node_size                           = lookup(each.value.data_factory_integration_runtime_azure_ssis, "node_size", null)
# #   number_of_nodes                     = lookup(each.value.data_factory_integration_runtime_azure_ssis, "number_of_nodes", null)
# #   maxmax_parallel_executions_per_node = lookup(each.value.data_factory_integration_runtime_azure_ssis, "max_parallel_executions_per_node", null)
# #   edition                             = lookup(each.value.data_factory_integration_runtime_azure_ssis, "edition", null)
# #   license_type                        = lookup(each.value.data_factory_integration_runtime_azure_ssis, "license_type", null)

# #   dynamic "catalog_info" {
# #     for_each = try(length(each.value.catalog_info), 0) > 0 ? [each.value.catalog_info] : []

# #     content {
# #       server_endpoint        = lookup(catalog_info.value, "server_endpoint", null)
# #       administrator_login    = lookup(catalog_info.value, "administrator_login", null)
# #       administrator_password = lookup(catalog_info.value, "administrator_password", null)
# #       pricing_tier           = lookup(catalog_info.value, "pricing_tier", null)
# #       daul_standby_pair_name = lookup(catalog_info.value, "dual_standby_pair_name", null)
# #     }
# #   }

# #   dynamic "custom_setup_script" {
# #     for_each = try(length(each.value.custom_setup_script),0) > 0 ? [each.value.custom_setup_script] : []

# #     content {
# #         blob_container_uri = lookup(catalog_info.value, "blob_container_uri", null)
# #         sas_token          = lookup(catalog_info.value, "sas_token", null)
# #     }
# #   }


# # }