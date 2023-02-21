locals {
  storage_container_list = flatten([
    for storage_key, storage_config in local.storage_config : [
      for k, v in coalesce(storage_config.containers, []) :
      {
        name                  = v.name
        container_access_type = v.container_access_type
        storage_key           = storage_key
        metadata              = v.metadata
      }
    ]
  ])

  containers = {
    for container in local.storage_container_list :
    lower(format("%s/%s", container.storage_key, container.name)) => container
  }
}

resource "azurerm_storage_container" "container" {
  for_each              = local.containers
  name                  = each.value.name
  storage_account_name  = azurerm_storage_account.storage_account[each.value.storage_key].name
  container_access_type = each.value.container_access_type
  metadata              = each.value.metadata
}