locals {
  admin_key_vault_id = var.admin_key_vault_id

  encryption_keys = {
    for synapse_key, synapse_config in local.synapse_with_cmk : synapse_config.cmk_key => {
      cmk_name            = synapse_config.customer_managed_key_name
      encryption_key_name = upper(format("%s-%s", synapse_config.name, synapse_config.customer_managed_key_name))
      synapse_key         = synapse_key
      key_vault_id        = local.admin_key_vault_id
      key_type            = "RSA"
      key_size            = 2048
      key_opts = [
        "unwrapKey",
        "wrapKey"
      ]
      identity_type       = synapse_config.identity.type
      user_identity_names = try(synapse_config.identity.user_identity_names, [])
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

data "azurerm_client_config" "current" {
}

data "azurerm_role_definition" "kv_encryption_role" {
  name = "Key Vault Crypto Service Encryption User"
}

locals {
  encryption_key_role_assignment_list = flatten(concat([
    for encryption_key, encryption_config in local.encryption_keys : [
      for identity in encryption_config.user_identity_names : {
        role_assignment_key = lower(format("%s/%s/service-encryption-user", encryption_key, identity))
        identity_key        = lower(format("%s/%s", encryption_config.synapse_key, identity))
        role_definition_id  = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.kv_encryption_role.id)
        key_vault_id        = local.admin_key_vault_id
        synapse_key         = encryption_config.synapse_key
      }
    ] if encryption_config.identity_type != "SystemAssigned"
    ],
    [
      for encryption_key, encryption_config in local.encryption_keys : [
        {
          role_assignment_key = lower(format("%s/system-assigned/service-encryption-user", encryption_key))
          identity_key        = null
          role_definition_id  = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.kv_encryption_role.id)
          key_vault_id        = local.admin_key_vault_id
          synapse_key         = encryption_config.synapse_key
        }
      ] if encryption_config.identity_type == "SystemAssigned"
    ]
  ))

  encryption_key_role_assignments = {
    for role_assignment in local.encryption_key_role_assignment_list : role_assignment.role_assignment_key => role_assignment
  }
}

resource "azurerm_role_assignment" "key_vault_role_assignment" {
  for_each           = local.encryption_key_role_assignments
  scope              = each.value.key_vault_id
  role_definition_id = each.value.role_definition_id
  principal_id       = each.value.identity_key != null ? azurerm_user_assigned_identity.user_assigned_identity[each.value.identity_key].principal_id : azurerm_synapse_workspace.synapse_workspace[each.value.synapse_key].identity[0].principal_id
}
