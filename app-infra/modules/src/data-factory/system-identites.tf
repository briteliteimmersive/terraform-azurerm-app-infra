locals {
  data_factory_with_system_identities = {
    for data_factory_key, data_factory_config in local.data_factory_configs : data_factory_key => data_factory_config if try(lower(data_factory_config.identity.type) != "userassigned", false)
  }

  data_factory_system_identity_list = [
    for data_factory_key, data_factory_config in local.data_factory_with_system_identities :
    {
      identity_key              = lower(format("%s/system-identity", data_factory_key))
      data_factory_key          = data_factory_key
      keyvault_linked_services  = data_factory_config.keyvault_linked_services
      adls_gen2_linked_services = data_factory_config.adls_gen2_linked_services
    }
  ]

  data_factory_system_identities = {
    for identity in local.data_factory_system_identity_list : identity.identity_key => identity
  }
}

## Role assignments for System identities

## KV role assignment
locals {
  data_factory_system_identities_kv_role_assignments_list = flatten([
    for identity_key, identity in local.data_factory_system_identities : [
      for keyvault in identity.keyvault_linked_services : [
        {
          identity_kv_role_assignment_key = lower(format("%s/%s", identity_key, keyvault.key_vault_name))
          key_vault_id                    = keyvault.key_vault_id
          data_factory_key                = identity.data_factory_key
        }
      ]
    ]
  ])

  data_factory_system_identities_with_kv_role_assignments = {
    for linked_services_role_assignment in local.data_factory_system_identities_kv_role_assignments_list : linked_services_role_assignment.identity_kv_role_assignment_key => linked_services_role_assignment
  }
}

resource "azurerm_role_assignment" "adf_system_identity_kv_secrets_builtin_role" {
  for_each           = local.data_factory_system_identities_with_kv_role_assignments
  scope              = each.value.key_vault_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.kv_secrets_builtin_role.id)
  principal_id       = azurerm_data_factory.data_factory[each.value.data_factory_key].identity.0.principal_id
}

## Storage role assignment
locals {
  data_factory_system_identities_adls_gen2_role_assignments_list = flatten([
    for identity_key, identity in local.data_factory_system_identities : [
      for adls_gen2 in identity.adls_gen2_linked_services : [
        {
          identity_adls_gen2_role_assignment_key = lower(format("%s/%s", identity_key, adls_gen2.storage_account_name))
          storage_account_id                     = adls_gen2.storage_account_id
          data_factory_key                       = identity.data_factory_key
        }
      ]
    ]
  ])

  data_factory_system_identities_with_adls_gen2_role_assignments = {
    for linked_services_role_assignment in local.data_factory_system_identities_adls_gen2_role_assignments_list : linked_services_role_assignment.identity_adls_gen2_role_assignment_key => linked_services_role_assignment
  }
}

resource "azurerm_role_assignment" "adf_system_identity_storage_admin_builtin_role" {
  for_each           = local.data_factory_system_identities_with_adls_gen2_role_assignments
  scope              = each.value.storage_account_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.storage_contributor_builtin_role.id)
  principal_id       = azurerm_data_factory.data_factory[each.value.data_factory_key].identity.0.principal_id
}