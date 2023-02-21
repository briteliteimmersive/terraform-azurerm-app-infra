locals {
  storage_config = {
    for storage_config in var.storage_acc_configs : storage_config.resource_key => storage_config
  }


}

resource "azurerm_storage_account" "storage_account" {
  for_each                          = local.storage_config
  name                              = each.value.name
  resource_group_name               = each.value.resource_group_name
  location                          = each.value.location
  account_tier                      = each.value.account_tier
  account_kind                      = each.value.account_kind
  access_tier                       = each.value.access_tier
  cross_tenant_replication_enabled  = each.value.cross_tenant_replication_enabled
  edge_zone                         = each.value.edge_zone
  enable_https_traffic_only         = each.value.enable_https_traffic_only
  shared_access_key_enabled         = each.value.shared_access_key_enabled
  account_replication_type          = each.value.account_replication_type
  min_tls_version                   = each.value.min_tls_version
  is_hns_enabled                    = each.value.is_hns_enabled
  sftp_enabled                      = each.value.sftp_enabled
  large_file_share_enabled          = each.value.large_file_share_enabled
  allow_nested_items_to_be_public   = each.value.allow_nested_items_to_be_public
  infrastructure_encryption_enabled = each.value.infrastructure_encryption_enabled

  dynamic "blob_properties" {
    for_each = try(length(each.value.blob_properties), 0) > 0 ? [each.value.blob_properties] : []
    content {
      versioning_enabled  = blob_properties.value.versioning_enabled
      change_feed_enabled = blob_properties.value.change_feed_enabled

      dynamic "container_delete_retention_policy" {
        for_each = try(length(blob_properties.value.container_delete_retention_policy), 0) > 0 ? [blob_properties.value.container_delete_retention_policy] : []

        content {
          days = container_delete_retention_policy.value.days
        }
      }

      dynamic "delete_retention_policy" {
        for_each = try(length(blob_properties.value.delete_retention_policy), 0) > 0 ? [blob_properties.value.delete_retention_policy] : []

        content {
          days = delete_retention_policy.value.days
        }
      }
    }
  }

  dynamic "network_rules" {
    for_each = each.value.network_rules != null ? [each.value.network_rules] : []
    content {
      default_action             = network_rules.value.default_action
      bypass                     = network_rules.value.bypass
      ip_rules                   = network_rules.value.ip_rules
      virtual_network_subnet_ids = network_rules.value.virtual_network_subnet_ids
    }
  }

  tags = each.value.tags

}