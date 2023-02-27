locals {
  data_factory_with_user_identities = {
    for data_factory_key, data_factory_config in local.data_factory_configs : data_factory_key => data_factory_config if try(lower(data_factory_config.identity.type) == "userassigned", false)
  }
  data_factory_with_system_identities = {
    for data_factory_key, data_factory_config in local.data_factory_configs : data_factory_key => data_factory_config if try(lower(data_factory_config.identity.type) == "systemassigned", false)
  }
  data_factory_identity_list = flatten([
    for data_factory_key, data_factory_config in local.data_factory_with_user_identities : [
      for data_factory_identity in data_factory_config.identity.user_identity_names : {
        identity_key        = "${data_factory_key}_${data_factory_identity}"
        name                = data_factory_identity
        resource_group_name = data_factory_config.resource_group_name
        location            = data_factory_config.location
        tags                = data_factory_config.tags
        data_factory_key    = data_factory_key
      }
    ]
  ])

  data_factory_identities = {
    for identity in local.data_factory_identity_list : identity.identity_key => identity
  }
  data_factory_with_identities = {
    for data_factory_key, data_factory_config in local.data_factory_configs : data_factory_key => data_factory_config if try(length(data_factory_config.identity) > 0, false)
  }
}
resource "azurerm_user_assigned_identity" "data_factory_identities" {
  for_each            = local.data_factory_identities
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}

data "azurerm_role_definition" "kv_admin_builtin_role" {
  name = "Key Vault Administrator"
}

resource "azurerm_role_assignment" "data_factory_identity_kv_admin_builtin_role" {
  for_each           = local.data_factory_identities #local.data_factory_with_identities
  scope              = local.app_key_vault_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.kv_admin_builtin_role.id)
  principal_id       = azurerm_user_assigned_identity.data_factory_identities[each.value.identity_key].principal_id
}

resource "azurerm_role_assignment" "data_factory_system_identity_kv_admin_builtin_role" {
  for_each           = local.data_factory_with_system_identities
  scope              = local.app_key_vault_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.kv_admin_builtin_role.id)
  principal_id       = azurerm_data_factory.data_factory["${each.value.resource_group_name}-${each.value.name}"].identity.0.principal_id
}