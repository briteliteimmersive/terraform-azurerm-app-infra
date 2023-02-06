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
        linked_services     = synapse_config.workspace_linked_services
      }
    ]
  ])

  synapse_user_identities = {
    for synapse_identity in local.synapse_user_identity_list : synapse_identity.identity_key => synapse_identity
  }

  synapse_linked_service_role_assignments_list = flatten([
    for identity_key, identity in local.synapse_user_identities : [
      for linked_service in identity.linked_services : {
        linked_service_role_assignment_key = lower(format("%s/%s/%s", identity.identity_key, linked_service.linked_service_id, local.role_by_linked_service_type[lower(linked_service.type)]))
        linked_service_identity_key        = identity.identity_key
        synapse_key                        = identity.synapse
        linked_service_id                  = linked_service.linked_service_id
        role_name                          = local.role_by_linked_service_type[lower(linked_service.type)]
      }
    ]
  ])

  synapse_linked_service_role_assignments = {
    for role_assignment in local.synapse_linked_service_role_assignments_list : role_assignment.linked_service_role_assignment_key => role_assignment
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

resource "azurerm_role_assignment" "usrassigned_linked_svc_role_assignment" {
  for_each           = local.synapse_linked_service_role_assignments
  scope              = each.value.linked_service_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.linked_service_role[each.value.role_name].id)
  principal_id       = azurerm_user_assigned_identity.user_assigned_identity[each.value.linked_service_identity_key].principal_id
}