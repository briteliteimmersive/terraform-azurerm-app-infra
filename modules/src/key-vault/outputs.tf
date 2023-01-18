locals {
  key_vault_output_properties = ["id", "name", "resource_group_name"]
  module_output = {
    for key_vault_key, key_vault_config in azurerm_key_vault.key_vault : key_vault_key => {
      for key, value in key_vault_config : key => value if contains(local.key_vault_output_properties, key)
    }
  }

}

output "outputs" {
  value = local.module_output
  depends_on = [
    azurerm_role_assignment.role_assignment
  ]
}