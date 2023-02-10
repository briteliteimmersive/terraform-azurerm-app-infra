locals {
  cosmosdb_configs = {
    for cosmosdb_key, cosmosdb_config in var.cosmosdb_configs : cosmosdb_config.resource_key => cosmosdb_config
  }
}

resource "azurerm_cosmosdb_account" "cosmosdb_account" {
  for_each                  = local.cosmosdb_configs
  name                      = each.value.name
  location                  = each.value.location
  resource_group_name       = each.value.resource_group_name
  offer_type                = each.value.offer_type
  kind                      = each.value.kind
  enable_automatic_failover = each.value.enable_automatic_failover
  dynamic "capabilities" {
    for_each = each.value.capabilities != null ? each.value.capabilities : []
    content {
      name = capabilities.value
    }
  }
  consistency_policy {
    consistency_level       = each.value.consistency_policy.consistency_level
    max_interval_in_seconds = each.value.consistency_policy.max_interval_in_seconds
    max_staleness_prefix    = each.value.consistency_policy.max_staleness_prefix
  }
  dynamic "geo_location" {
    for_each = each.value.geo_location
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = geo_location.value.zone_redundant
    }
  }
  create_mode                           = each.value.backup != null ? each.value.backup.type == "Continuous" ? each.value.create_mode : null : null
  default_identity_type                 = each.value.default_identity_type
  ip_range_filter                       = each.value.ip_range_filter
  enable_free_tier                      = each.value.enable_free_tier
  public_network_access_enabled         = each.value.public_network_access_enabled
  is_virtual_network_filter_enabled     = each.value.is_virtual_network_filter_enabled
  key_vault_key_id                      = each.value.key_vault_key_id
  enable_multiple_write_locations       = each.value.enable_multiple_write_locations
  access_key_metadata_writes_enabled    = each.value.access_key_metadata_writes_enabled
  mongo_server_version                  = each.value.mongo_server_version
  network_acl_bypass_for_azure_services = each.value.network_acl_bypass_for_azure_services
  network_acl_bypass_ids                = each.value.network_acl_bypass_ids
  local_authentication_disabled         = each.value.local_authentication_disabled
  dynamic "virtual_network_rule" {
    for_each = each.value.virtual_network_rule != null ? each.value.virtual_network_rule : []
    content {
      id                                   = virtual_network_rule.value.id
      ignore_missing_vnet_service_endpoint = virtual_network_rule.value.ignore_missing_vnet_service_endpoint
    }
  }
  analytical_storage_enabled = each.value.analytical_storage_enabled
  dynamic "analytical_storage" {
    for_each = each.value.analytical_storage != null ? [each.value.analytical_storage] : []
    content {
      schema_type = each.value.analytical_storage.schema_type
    }
  }
  dynamic "capacity" {
    for_each = each.value.capacity != null ? [each.value.capacity] : []
    content {
      total_throughput_limit = capacity.value.total_throughput_limit
    }
  }
  dynamic "backup" {
    for_each = each.value.backup != null ? [each.value.backup] : []
    content {
      type                = backup.value.type
      interval_in_minutes = backup.value.type == "Periodic" ? backup.value.interval_in_minutes : null
      retention_in_hours  = backup.value.type == "Periodic" ? backup.value.retention_in_hours : null
      storage_redundancy  = backup.value.type == "Periodic" ? backup.value.storage_redundancy : null
    }
  }
  dynamic "cors_rule" {
    for_each = each.value.cors_rule != null ? [each.value.cors_rule] : []
    content {
      allowed_headers    = cors_rule.value.allowed_headers
      allowed_methods    = cors_rule.value.allowed_methods
      allowed_origins    = cors_rule.value.allowed_origins
      exposed_headers    = cors_rule.value.exposed_headers
      max_age_in_seconds = cors_rule.value.max_age_in_seconds
    }
  }
  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type = identity.value.type
    }
  }
  dynamic "restore" {
    for_each = each.value.create_mode == "Restore" ? each.value.restore != null ? [each.value.restore] : [] : []
    content {
      source_cosmosdb_account_id = restore.value.source_cosmosdb_account_id
      restore_timestamp_in_utc   = restore.value.restore_timestamp_in_utc
      dynamic "database" {
        for_each = restore.value.database
        content {
          name             = database.value.name
          collection_names = database.value.collection_names
        }
      }
    }
  }
  tags = each.value.tags

}