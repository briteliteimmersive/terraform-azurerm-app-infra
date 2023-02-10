locals {
  key_vault_secrets_output_properties = ["id"]
  module_output = {
    for key_vault_key, key_vault_config in azurerm_key_vault_secret.secret : "${key_vault_key}" => {
      for key, value in key_vault_config : key => value if contains(local.key_vault_secrets_output_properties, key)
    }
  }

}

output "outputs" {
  value = local.module_output
}