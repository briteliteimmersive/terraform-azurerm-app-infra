locals {
  app_key_vault_id = var.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sql_fqdn" {
  for_each     = local.mssql_server_config
  name         = upper(replace(format("%s-server-fqdn", each.value.name), "_", "-"))
  value        = azurerm_mssql_server.sql_server[each.key].fully_qualified_domain_name
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sql_admin_login" {
  for_each     = local.mssql_server_config
  name         = upper(replace(format("%s-server-local-admin-user", each.value.name), "_", "-"))
  value        = azurerm_mssql_server.sql_server[each.key].administrator_login
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  for_each     = local.mssql_server_config
  name         = upper(replace(format("%s-server-local-admin-password", each.value.name), "_", "-"))
  value        = azurerm_mssql_server.sql_server[each.key].administrator_login_password
  key_vault_id = local.app_key_vault_id
}