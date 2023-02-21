locals {
  app_key_vault_id = var.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sa_primary_access_key" {
  for_each     = local.storage_config
  name         = upper(replace(format("%s-primary-access-key", each.value.name), "_", "-"))
  value        = azurerm_storage_account.storage_account[each.key].primary_access_key
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sa_primary_connection_string" {
  for_each     = local.storage_config
  name         = upper(replace(format("%s-primary-connection-string", each.value.name), "_", "-"))
  value        = azurerm_storage_account.storage_account[each.key].primary_connection_string
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sa_primary_blob_connection_string" {
  for_each     = local.storage_config
  name         = upper(replace(format("%s-primary-blob-connection-string", each.value.name), "_", "-"))
  value        = azurerm_storage_account.storage_account[each.key].primary_blob_connection_string
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sa_secondary_access_key" {
  for_each     = local.storage_config
  name         = upper(replace(format("%s-secondary-access-key", each.value.name), "_", "-"))
  value        = azurerm_storage_account.storage_account[each.key].secondary_access_key
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sa_secondary_connection_string" {
  for_each     = local.storage_config
  name         = upper(replace(format("%s-secondary-connection-string", each.value.name), "_", "-"))
  value        = azurerm_storage_account.storage_account[each.key].secondary_connection_string
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sa_secondary_blob_connection_string" {
  for_each     = local.storage_config
  name         = upper(replace(format("%s-secondary-blob-connection-string", each.value.name), "_", "-"))
  value        = azurerm_storage_account.storage_account[each.key].secondary_blob_connection_string
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sa_primary_file_endpoint" {
  for_each     = local.storage_config
  name         = upper(replace(format("%s-primary-file-endpoint", each.value.name), "_", "-"))
  value        = azurerm_storage_account.storage_account[each.key].primary_file_endpoint
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "storage_user_password" {
  for_each     = local.local_users_with_password_enabled
  name         = upper(replace(format("%s-%s-password", azurerm_storage_account.storage_account[each.value.storage_key].name, each.value.name), "_", "-"))
  value        = azurerm_storage_account_local_user.storage_local_user[each.key].password
  key_vault_id = local.app_key_vault_id
}