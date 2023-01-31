locals {

  synapse_user_identity_list = flatten([
    for synapse_key, synapse_config in local.synapse_with_user_identities : [
      for synapse_identity in synapse_config.identity.user_identity_names : {
        synapse_key         = synapse_config.resource_key
        identity_key        = lower(format("%s/%s", synapse_key, synapse_identity))
        name                = synapse_identity
        resource_group_name = synapse_config.resource_group_name
        location            = synapse_config.location
        tags                = synapse_config.tags
        storage_account_id  = synapse_config.storage_account_id
      }
    ]
  ])

  synapse_user_identities = {
    for synapse_identity in local.synapse_user_identity_list : synapse_identity.identity_key => synapse_identity
  }
}

resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  for_each            = local.synapse_user_identities
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}

resource "azurerm_role_assignment" "usrassigned_storage_role_assignment" {
  for_each           = local.synapse_user_identities
  scope              = each.value.storage_account_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.storage_blob_role.id)
  principal_id       = azurerm_user_assigned_identity.user_assigned_identity[each.key].principal_id
}