locals {
  function_apps_with_user_identities = {
    for function_apps_key, function_apps_config in local.linux_function_app_configs : function_apps_key => function_apps_config if try(lower(function_apps_config.identity.type) == "userassigned", false)
  }

  function_apps_user_identity_list = flatten([
    for function_apps_key, function_apps_config in local.function_apps_with_user_identities : [
      for function_apps_identity in function_apps_config.identity.user_identity_names : {
        identity_key        = lower(format("%s/%s", function_apps_key, function_apps_identity))
        name                = function_apps_identity
        resource_group_name = function_apps_config.resource_group_name
        location            = function_apps_config.location
        tags                = function_apps_config.tags
        function_apps_key   = function_apps_key
        storage_account_id  = function_apps_config.storage_account_id
        # container_registry_id  = function_apps_config.site_config.container_registry_id
        keyvault_identity_name = try(lower(function_apps_config.keyvault_identity_name), "") == lower(function_apps_identity) ? function_apps_config.keyvault_identity_name : null
      }
    ]
  ])

  function_apps_user_identities = {
    for identity in local.function_apps_user_identity_list : identity.identity_key => identity
  }
}

resource "azurerm_user_assigned_identity" "function_apps_identities" {
  for_each            = local.function_apps_user_identities
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}

## User identity role assignments
data "azurerm_client_config" "current" {
}

## KV role assignment
locals {
  function_apps_user_identities_with_kvref = {
    for identity_key, identity in local.function_apps_user_identities : identity_key => identity if identity.keyvault_identity_name != null
  }
}

data "azurerm_role_definition" "kv_admin_builtin_role" {
  name = "Key Vault Administrator"
}

resource "azurerm_role_assignment" "function_app_usr_identity_kv_admin_builtin_role" {
  for_each           = local.function_apps_user_identities_with_kvref
  scope              = local.app_key_vault_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.kv_admin_builtin_role.id)
  principal_id       = azurerm_user_assigned_identity.function_apps_identities[each.key].principal_id
}

## Storage role assignment
locals {
  function_apps_user_identities_with_storage_id = {
    for identity_key, identity in local.function_apps_user_identities : identity_key => identity if identity.storage_account_id != null
  }
}

data "azurerm_role_definition" "storage_contributor_builtin_role" {
  name = "Storage Account Contributor"
}

resource "azurerm_role_assignment" "function_app_user_identity_storage_admin_builtin_role" {
  for_each           = local.function_apps_user_identities_with_storage_id
  scope              = each.value.storage_account_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.storage_contributor_builtin_role.id)
  principal_id       = azurerm_user_assigned_identity.function_apps_identities[each.key].principal_id
}

# ## Container Registry role assignment
# locals {
#   function_apps_user_identities_with_container_registry_id = {
#     for identity_key, identity in local.function_apps_user_identities : identity_key => identity if identity.container_registry_id != null
#   }
# }

# data "azurerm_role_definition" "acr_builtin_role_acr_pull" {
#   name = "AcrPull"
# }

# resource "azurerm_role_assignment" "function_app_user_identity_acr_pull_builtin_role" {
#   for_each           = local.function_apps_user_identities_with_container_registry_id
#   scope              = each.value.container_registry_id
#   role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.acr_builtin_role_acr_pull.id)
#   principal_id       = azurerm_user_assigned_identity.function_apps_identities[each.key].principal_id
# }