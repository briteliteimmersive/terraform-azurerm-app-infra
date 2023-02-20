locals {
  app_key_vault_id = var.app_key_vault_id
}

resource "azurerm_key_vault_secret" "vm_password" {
  for_each     = local.vms
  name         = upper(replace(format("%s-vm-password", each.value.hostname), "_", "-"))
  value        = azurerm_linux_virtual_machine.linux_vm[each.key].admin_password
  key_vault_id = local.app_key_vault_id
}
