locals {
  storage_local_users_list = flatten([
    for storage_key, storage_config in local.storage_config : [
      for local_user in coalesce(storage_config.local_users, []) : merge(local_user, {
        user_key    = lower(format("%s/%s", storage_key, local_user.name))
        storage_key = storage_key
      })
    ]
  ])

  local_users = {
    for local_user in local.storage_local_users_list : local_user.user_key => local_user
  }

  local_users_with_password_enabled = {
    for user_key, local_user in local.local_users : user_key => local_user if local_user.ssh_password_enabled
  }
}

resource "azurerm_storage_account_local_user" "storage_local_user" {
  for_each             = local.local_users
  name                 = each.value.name
  storage_account_id   = azurerm_storage_account.storage_account[each.value.storage_key].id
  ssh_key_enabled      = each.value.ssh_key_enabled
  ssh_password_enabled = each.value.ssh_password_enabled
  home_directory       = each.value.home_directory

  dynamic "ssh_authorized_key" {
    for_each = try(length(each.value.ssh_authorized_key) > 0, false) ? each.value.ssh_authorized_key : []

    content {
      description = ssh_authorized_key.value.description
      key         = ssh_authorized_key.value.key
    }
  }

  dynamic "permission_scope" {
    for_each = try(length(each.value.permission_scope) > 0, false) ? each.value.permission_scope : []

    content {
      permissions {
        read   = permission_scope.value.permissions.read
        create = permission_scope.value.permissions.create
        delete = permission_scope.value.permissions.delete
        list   = permission_scope.value.permissions.list
        write  = permission_scope.value.permissions.write
      }
      service       = permission_scope.value.service
      resource_name = permission_scope.value.resource_name
    }

  }

  depends_on = [
    azurerm_storage_container.container,
    azurerm_storage_share.storage_share
  ]

}