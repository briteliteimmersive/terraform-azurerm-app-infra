locals {

  storage_share_list = flatten([
    for storage_key, storage_config in local.storage_config : [
      for k, v in coalesce(storage_config.file_shares, []) : merge(
        {
          storage_key = storage_key
        }
      , v)
    ]
  ])

  storage_shares = {
    for file_share in local.storage_share_list :
    lower(format("%s/%s", file_share.storage_key, file_share.name)) => file_share
  }
}

resource "azurerm_storage_share" "storage_share" {
  for_each             = local.storage_shares
  name                 = each.value.name
  storage_account_name = azurerm_storage_account.storage_account[each.value.storage_key].name
  quota                = each.value.quota
}