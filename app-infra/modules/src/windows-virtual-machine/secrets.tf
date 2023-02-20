locals {
  app_key_vault_id = var.app_key_vault_id
}

resource "azurerm_key_vault_secret" "vm_password" {
  for_each     = local.vms
  name         = upper(replace(format("%s-vm-password", each.value.hostname), "_", "-"))
  value        = azurerm_windows_virtual_machine.windows_vm[each.key].admin_password
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sql_username" {
  for_each     = local.sql_vms
  name         = upper(replace(format("%s-sql-administrator", each.value.vm_name), "_", "-"))
  value        = each.value.sql_connectivity_update_username
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "sql_password" {
  for_each     = local.sql_vms
  name         = upper(replace(format("%s-sql-password", each.value.vm_name), "_", "-"))
  value        = random_password.sql_password[each.key].result
  key_vault_id = local.app_key_vault_id
}
