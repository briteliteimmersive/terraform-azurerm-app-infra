locals {
  cosmosdb_mongodb = {
    for cosmosdb_mongodb in var.cosmosdb_mongodb_configs : cosmosdb_mongodb.resource_key => cosmosdb_mongodb
  }

  cosmosdb_mongodb_collection_configs = flatten([
    for mongodb_key, mongodb_config in local.cosmosdb_mongodb : [
      for collection in mongodb_config.collections : [
        merge(collection, {
          collection_key = lower(format("%s/%s", mongodb_key, collection.name))
          mongodb_key    = mongodb_key
        })
      ]
    ]
  ])

  cosmosdb_mongodb_collection = {
    for cosmosdb_mongodb_collection in local.cosmosdb_mongodb_collection_configs : cosmosdb_mongodb_collection.collection_key => cosmosdb_mongodb_collection
  }
}

resource "azurerm_cosmosdb_mongo_database" "cosmosdb_mongodb_database" {
  for_each            = local.cosmosdb_mongodb
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  account_name        = each.value.account_name
  throughput          = each.value.throughput
  dynamic "autoscale_settings" {
    for_each = try(length(each.value.autoscale_settings), 0) > 0 ? [each.value.autoscale_settings] : []
    content {
      max_throughput = autoscale_settings.value.max_throughput
    }
  }
}

resource "azurerm_cosmosdb_mongo_collection" "cosmosdb_mongodb_collection" {
  for_each               = local.cosmosdb_mongodb_collection
  name                   = each.value.name
  resource_group_name    = azurerm_cosmosdb_mongo_database.cosmosdb_mongodb_database[each.value.mongodb_key].resource_group_name
  account_name           = azurerm_cosmosdb_mongo_database.cosmosdb_mongodb_database[each.value.mongodb_key].account_name
  database_name          = azurerm_cosmosdb_mongo_database.cosmosdb_mongodb_database[each.value.mongodb_key].name
  shard_key              = each.value.shard_key
  throughput             = each.value.throughput
  default_ttl_seconds    = each.value.default_ttl_seconds
  analytical_storage_ttl = each.value.analytical_storage_ttl

  dynamic "index" {
    for_each = try(length(each.value.index), 0) > 0 ? each.value.index : []

    content {
      keys   = index.value.keys
      unique = index.value.unique
    }
  }

  dynamic "autoscale_settings" {
    for_each = try(length(each.value.autoscale_settings), 0) > 0 ? [each.value.autoscale_settings] : []

    content {
      max_throughput = autoscale_settings.value.max_throughput
    }
  }

}