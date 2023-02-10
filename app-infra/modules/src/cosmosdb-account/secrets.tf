locals {
  app_key_vault_id = var.app_key_vault_id
}

resource "azurerm_key_vault_secret" "cosmosdb_primary_key" {
  for_each     = local.cosmosdb_configs
  name         = upper(replace(format("%s-primary-key", each.value.name), "_", "-"))
  value        = azurerm_cosmosdb_account.cosmosdb_account[each.key].primary_key
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "cosmosdb_secondary_key" {
  for_each     = local.cosmosdb_configs
  name         = upper(replace(format("%s-secondary-key", each.value.name), "_", "-"))
  value        = azurerm_cosmosdb_account.cosmosdb_account[each.key].secondary_key
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "cosmosdb_primary_readonly_key" {
  for_each     = local.cosmosdb_configs
  name         = upper(replace(format("%s-primary-readonly-key", each.value.name), "_", "-"))
  value        = azurerm_cosmosdb_account.cosmosdb_account[each.key].primary_readonly_key
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "cosmosdb_secondary_readonly_key" {
  for_each     = local.cosmosdb_configs
  name         = upper(replace(format("%s-secondary-readonly-key", each.value.name), "_", "-"))
  value        = azurerm_cosmosdb_account.cosmosdb_account[each.key].secondary_readonly_key
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "cosmosdb_connection_string_1" {
  for_each     = local.cosmosdb_configs
  name         = upper(replace(format("%s-connection-string-01", each.value.name), "_", "-"))
  value        = azurerm_cosmosdb_account.cosmosdb_account[each.key].connection_strings[0]
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "cosmosdb_connection_string_2" {
  for_each     = local.cosmosdb_configs
  name         = upper(replace(format("%s-connection-string-02", each.value.name), "_", "-"))
  value        = azurerm_cosmosdb_account.cosmosdb_account[each.key].connection_strings[1]
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "cosmosdb_connection_string_3" {
  for_each     = local.cosmosdb_configs
  name         = upper(replace(format("%s-connection-string-03", each.value.name), "_", "-"))
  value        = azurerm_cosmosdb_account.cosmosdb_account[each.key].connection_strings[2]
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "cosmosdb_connection_string_4" {
  for_each     = local.cosmosdb_configs
  name         = upper(replace(format("%s-connection-string-04", each.value.name), "_", "-"))
  value        = azurerm_cosmosdb_account.cosmosdb_account[each.key].connection_strings[3]
  key_vault_id = local.app_key_vault_id
}