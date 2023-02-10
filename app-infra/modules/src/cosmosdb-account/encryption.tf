locals {
  admin_key_vault_id = var.admin_key_vault_id

  encryption_keys = {
    for cosmosdb_key, cosmosdb_config in local.cosmosdb_with_cmk_encryption : cosmosdb_config.cmk_key => {
      encryption_key_name = upper(format("%s-ENCRYPTION-CMK", cosmosdb_config.name))
      cosmosdb_key        = cosmosdb_key
      key_vault_id        = local.admin_key_vault_id
      key_type            = "RSA"
      key_size            = 2048
      key_opts = [
        "unwrapKey",
        "wrapKey"
      ]
      principal_id = "5c780161-6b44-410c-8e85-30492b357678" ## Azure Cosmos DB principal ID
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
  principal_id       = each.value.principal_id
}
