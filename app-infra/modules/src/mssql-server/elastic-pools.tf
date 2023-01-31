locals {
  sql_elasticpools_list = flatten([
    for sql_key, sql_server in local.mssql_server_config : [
      for elastic_pool in coalesce(sql_server.elastic_pools, []) :
      merge(elastic_pool, {
        elastic_pool_key = lower(format("%s/%s", sql_key, elastic_pool.name))
        mssql_server_key = sql_key
      })
    ]
  ])

  sql_elasticpools = {
    for elastic_pool in local.sql_elasticpools_list : elastic_pool.elastic_pool_key => elastic_pool
  }
}

resource "azurerm_mssql_elasticpool" "msql_elastic_pool" {
  for_each                       = local.sql_elasticpools
  name                           = each.value.name
  resource_group_name            = azurerm_mssql_server.sql_server[each.value.mssql_server_key].resource_group_name
  location                       = azurerm_mssql_server.sql_server[each.value.mssql_server_key].location
  server_name                    = azurerm_mssql_server.sql_server[each.value.mssql_server_key].name
  license_type                   = each.value.license_type
  max_size_gb                    = each.value.max_size_gb
  max_size_bytes                 = each.value.max_size_bytes
  maintenance_configuration_name = each.value.maintenance_configuration_name
  zone_redundant                 = each.value.zone_redundant

  sku {
    name     = each.value.sku.name
    tier     = each.value.sku.tier
    family   = each.value.sku.family
    capacity = each.value.sku.capacity
  }

  per_database_settings {
    min_capacity = each.value.per_database_settings.min_capacity
    max_capacity = each.value.per_database_settings.max_capacity
  }
  tags = azurerm_mssql_server.sql_server[each.value.mssql_server_key].tags
}