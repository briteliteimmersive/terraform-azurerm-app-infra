locals {
  function_apps_with_system_identities = {
    for function_apps_key, function_apps_config in local.linux_function_app_configs : function_apps_key => function_apps_config if try(lower(function_apps_config.identity.type) == "systemassigned", false)
  }

  function_apps_system_identity_list = [
    for function_apps_key, function_apps_config in local.function_apps_with_system_identities :
    {
      identity_key       = lower(format("%s/system-identity", function_apps_key))
      function_apps_key  = function_apps_key
      storage_account_id = function_apps_config.storage_account_id
      # container_registry_id = try(function_apps_config.site_config.container_registry_id, null)
    }
  ]

  function_apps_system_identities = {
    for identity in local.function_apps_system_identity_list : identity.identity_key => identity
  }
}

## Role assignments for System identities

## Storage role assignment
locals {
  function_apps_system_identities_with_storage_id = {
    for identity_key, identity in local.function_apps_system_identities : identity_key => identity if identity.storage_account_id != null
  }
}

resource "azurerm_role_assignment" "function_app_system_identity_storage_admin_builtin_role" {
  for_each           = local.function_apps_system_identities_with_storage_id
  scope              = each.value.storage_account_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.storage_contributor_builtin_role.id)
  principal_id       = azurerm_linux_function_app.linux_function_app[each.value.function_apps_key].identity.0.principal_id
}

# ## Container Registry role assignment
# locals {
#   function_apps_system_identities_with_container_registry_id = {
#     for identity_key, identity in local.function_apps_system_identities : identity_key => identity if identity.container_registry_id != null
#   }
# }

# resource "azurerm_role_assignment" "function_app_system_identity_acr_pull_builtin_role" {
#   for_each           = local.function_apps_system_identities_with_container_registry_id
#   scope              = each.value.container_registry_id
#   role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.acr_builtin_role_acr_pull.id)
#   principal_id       = azurerm_linux_function_app.linux_function_app[each.value.function_apps_key].identity.0.principal_id
# }