locals {
  key_vault_id = var.keyvault_secrets.key_vault_id

  key_vault_secrets = {
    for secret in var.keyvault_secrets.secrets : "${secret.secret_key}" => {
      secret_key   = secret.secret_key
      secret_value = secret.secret_value
      key_vault_id = local.key_vault_id
    }
  }
}

resource "azurerm_key_vault_secret" "secret" {
  for_each     = local.key_vault_secrets
  name         = each.value.secret_key
  value        = each.value.secret_value
  key_vault_id = each.value.key_vault_id
}