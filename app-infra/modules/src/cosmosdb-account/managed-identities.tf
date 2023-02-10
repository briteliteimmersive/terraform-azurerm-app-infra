locals {

  cosmosdb_user_identity_list = flatten([
    for cosmosdb_key, cosmosdb_config in local.cosmosdb_with_user_identities : [
      for cosmosdb_identity in cosmosdb_config.identity.user_identity_names : {
        cosmosdb_key        = cosmosdb_config.resource_key
        identity_key        = lower(format("%s/%s", cosmosdb_key, cosmosdb_identity))
        name                = cosmosdb_identity
        resource_group_name = cosmosdb_config.resource_group_name
        location            = cosmosdb_config.location
        tags                = cosmosdb_config.tags
      }
    ]
  ])

  cosmosdb_user_identities = {
    for cosmosdb_identity in local.cosmosdb_user_identity_list : cosmosdb_identity.identity_key => cosmosdb_identity
  }
}

resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  for_each            = local.cosmosdb_user_identities
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}