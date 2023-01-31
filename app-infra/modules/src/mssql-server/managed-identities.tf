locals {

  mssql_user_identity_list = flatten([
    for mssql_key, mssql_config in local.mssql_server_with_user_identities : [
      for mssql_identity in mssql_config.identity.user_identity_names : {
        mssql_key           = mssql_config.resource_key
        identity_key        = lower(format("%s/%s", mssql_key, mssql_identity))
        name                = mssql_identity
        resource_group_name = mssql_config.resource_group_name
        location            = mssql_config.location
        tags                = mssql_config.tags
        storage_account_id  = mssql_config.storage_account_id
      }
    ]
  ])

  mssql_user_identities = {
    for mssql_identity in local.mssql_user_identity_list : mssql_identity.identity_key => mssql_identity
  }
}

resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  for_each            = local.mssql_user_identities
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}