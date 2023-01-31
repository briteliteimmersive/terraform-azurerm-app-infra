locals {
  synapse_configs = {
    for synapse_config in var.synapse_configs : synapse_config.resource_key => merge(synapse_config, {
      cmk_key = try(lower(format("%s/%s", synapse_config.resource_key, synapse_config.customer_managed_key_name)), null)
    })
  }

  ## Synapse instances with customer managed key
  synapse_with_cmk = {
    for synapse_key, synapse_config in local.synapse_configs : synapse_key => synapse_config if synapse_config.customer_managed_key_name != null
  }

  ## Identities can be configured only when CMK is used
  synapse_with_user_identities = {
    for synapse_key, synapse_config in local.synapse_with_cmk : synapse_key => synapse_config
    if try(length(synapse_config.identity.user_identity_names) > 0, false)
  }

  synapse_without_user_identities = {
    for synapse_key, synapse_config in local.synapse_configs : synapse_key => synapse_config
    if try(length(synapse_config.identity.user_identity_names) == 0, true)
  }

  ## Synapse with AAD admins
  synapse_with_aad_admin = {
    for synapse_key, synapse_config in local.synapse_configs : synapse_key => synapse_config if synapse_config.workspace_aad_admin != null
  }

}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_filesystem" {
  for_each           = local.synapse_configs
  name               = each.value.filesystem_name
  storage_account_id = each.value.storage_account_id
}

resource "azurerm_synapse_workspace" "synapse_workspace" {
  for_each                             = local.synapse_configs
  name                                 = each.value.name
  resource_group_name                  = each.value.resource_group_name
  location                             = each.value.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_filesystem[each.key].id
  sql_administrator_login              = each.value.sql_administrator_login
  sql_administrator_login_password     = each.value.sql_administrator_login_password
  compute_subnet_id                    = each.value.compute_subnet_id
  data_exfiltration_protection_enabled = each.value.data_exfiltration_protection_enabled
  linking_allowed_for_aad_tenant_ids   = each.value.linking_allowed_for_aad_tenant_ids
  managed_virtual_network_enabled      = each.value.managed_virtual_network_enabled
  public_network_access_enabled        = each.value.public_network_access_enabled
  sql_identity_control_enabled         = each.value.sql_identity_control_enabled

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type = identity.value.type
      identity_ids = identity.value.type != "SystemAssigned" ? flatten([
        for identity in identity.value.user_identity_names : [
          azurerm_user_assigned_identity.user_assigned_identity[format("%s/%s", each.key, identity)].id
        ]
      ]) : null
    }
  }

  dynamic "customer_managed_key" {
    for_each = each.value.customer_managed_key_name != null ? [each.value.customer_managed_key_name] : []

    content {
      key_versionless_id = azurerm_key_vault_key.encryption_key[each.value.cmk_key].versionless_id
      key_name           = customer_managed_key.value
    }
  }

  tags = each.value.tags
}

data "azurerm_role_definition" "storage_blob_role" {
  name = "Storage Blob Data Contributor"
}

resource "azurerm_role_assignment" "sysassigned_storage_role_assignment" {
  for_each           = local.synapse_without_user_identities
  scope              = each.value.storage_account_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.storage_blob_role.id)
  principal_id       = azurerm_synapse_workspace.synapse_workspace[each.key].identity[0].principal_id
}

resource "azurerm_synapse_workspace_key" "synapse_workspace_key" {
  for_each                            = local.synapse_with_cmk
  customer_managed_key_versionless_id = azurerm_key_vault_key.encryption_key[each.value.cmk_key].versionless_id
  synapse_workspace_id                = azurerm_synapse_workspace.synapse_workspace[each.key].id
  active                              = true
  customer_managed_key_name           = each.value.customer_managed_key_name
  depends_on                          = [azurerm_role_assignment.key_vault_role_assignment]
}

resource "azurerm_synapse_workspace_aad_admin" "synapse_workspace_aad_admin" {
  for_each             = local.synapse_with_aad_admin
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace[each.key].id
  login                = each.value.workspace_aad_admin.login
  object_id            = each.value.workspace_aad_admin.object_id
  tenant_id            = data.azurerm_client_config.current.tenant_id

  depends_on = [azurerm_synapse_workspace_key.synapse_workspace_key]
}