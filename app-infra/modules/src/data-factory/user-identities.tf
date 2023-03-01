locals {
  data_factory_with_user_identities = {
    for data_factory_key, data_factory_config in local.data_factory_configs : data_factory_key => data_factory_config if try(lower(data_factory_config.identity.type) != "systemassigned", false)
  }

  data_factory_user_identity_list = flatten([
    for data_factory_key, data_factory_config in local.data_factory_with_user_identities : [
      for data_factory_identity in data_factory_config.identity.user_identity_names : {
        identity_key              = lower(format("%s/%s", data_factory_key, data_factory_identity))
        name                      = data_factory_identity
        resource_group_name       = data_factory_config.resource_group_name
        location                  = data_factory_config.location
        tags                      = data_factory_config.tags
        keyvault_linked_services  = data_factory_config.keyvault_linked_services
        adls_gen2_linked_services = data_factory_config.adls_gen2_linked_services
      }
    ]
  ])

  data_factory_user_identities = {
    for identity in local.data_factory_user_identity_list : identity.identity_key => identity
  }
}

resource "azurerm_user_assigned_identity" "data_factory_identities" {
  for_each            = local.data_factory_user_identities
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}

## User identity role assignments

## KV role assignment
locals {
  data_factory_user_identities_kv_role_assignments_list = flatten([
    for identity_key, identity in local.data_factory_user_identities : [
      for keyvault in identity.keyvault_linked_services : [
        {
          identity_kv_role_assignment_key = lower(format("%s/%s", identity_key, keyvault.key_vault_name))
          identity_key                    = identity_key
          key_vault_id                    = keyvault.key_vault_id
        }
      ]
    ]
  ])

  data_factory_user_identities_with_kv_role_assignments = {
    for linked_services_role_assignment in local.data_factory_user_identities_kv_role_assignments_list : linked_services_role_assignment.identity_kv_role_assignment_key => linked_services_role_assignment
  }
}

data "azurerm_role_definition" "kv_secrets_builtin_role" {
  name = "Key Vault Secrets User"
}

resource "azurerm_role_assignment" "adf_usr_identity_kv_secrets_builtin_role" {
  for_each           = local.data_factory_user_identities_with_kv_role_assignments
  scope              = each.value.key_vault_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.kv_secrets_builtin_role.id)
  principal_id       = azurerm_user_assigned_identity.data_factory_identities[each.value.identity_key].principal_id
}

## Storage role assignment
locals {
  data_factory_user_identities_adls_gen2_role_assignments_list = flatten([
    for identity_key, identity in local.data_factory_user_identities : [
      for adls_gen2 in identity.adls_gen2_linked_services : [
        {
          identity_adls_gen2_role_assignment_key = lower(format("%s/%s", identity_key, adls_gen2.storage_account_name))
          identity_key                           = identity_key
          storage_account_id                     = adls_gen2.storage_account_id
        }
      ]
    ]
  ])

  data_factory_user_identities_with_adls_gen2_role_assignments = {
    for linked_services_role_assignment in local.data_factory_user_identities_adls_gen2_role_assignments_list : linked_services_role_assignment.identity_adls_gen2_role_assignment_key => linked_services_role_assignment
  }
}

data "azurerm_role_definition" "storage_contributor_builtin_role" {
  name = "Storage Blob Data Contributor"
}

resource "azurerm_role_assignment" "adf_user_identity_storage_admin_builtin_role" {
  for_each           = local.data_factory_user_identities_with_adls_gen2_role_assignments
  scope              = each.value.storage_account_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.storage_contributor_builtin_role.id)
  principal_id       = azurerm_user_assigned_identity.data_factory_identities[each.value.identity_key].principal_id
}
