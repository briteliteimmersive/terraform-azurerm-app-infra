locals {
  admin_key_vault_id = var.admin_key_vault_id

  data_factory_with_cmk_encryption = {
    for adf_key, adf_config in local.data_factory_configs : adf_key => adf_config if adf_config.cmk_user_identity_key != null
  }

  encryption_keys = {
    for data_factory_key, data_factory_config in local.data_factory_with_cmk_encryption : data_factory_config.cmk_key => {
      encryption_key_name = upper(format("%s-ENCRYPTION-CMK", data_factory_config.name))
      data_factory_key    = data_factory_key
      key_vault_id        = local.admin_key_vault_id
      key_type            = "RSA"
      key_size            = 2048
      key_opts = [
        "unwrapKey",
        "wrapKey"
      ]
      cmk_user_identity_key = data_factory_config.cmk_user_identity_key
    }
  }

}

resource "azurerm_key_vault_key" "encryption_key" {
  for_each     = local.encryption_keys
  name         = each.value.encryption_key_name
  key_vault_id = each.value.key_vault_id
  key_type     = each.value.key_type
  key_size     = each.value.key_size
  key_opts     = each.value.key_opts
}

data "azurerm_role_definition" "kv_encryption_role" {
  name = "Key Vault Crypto Service Encryption User"
}

resource "azurerm_role_assignment" "key_vault_role_assignment" {
  for_each           = local.encryption_keys
  scope              = each.value.key_vault_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.kv_encryption_role.id)
  principal_id       = azurerm_user_assigned_identity.data_factory_identities[each.value.cmk_user_identity_key].principal_id
}
