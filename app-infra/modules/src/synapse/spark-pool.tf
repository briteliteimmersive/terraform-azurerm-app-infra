locals {
  spark_pool_list = flatten([
    for synapse_key, synapse_config in local.synapse_configs : [
      for spark_pool in synapse_config.spark_pools : merge(spark_pool, {
        spark_pool_key = lower(format("%s/%s", synapse_key, spark_pool.name))
        synapse_key    = synapse_key
        tags           = synapse_config.tags
      })
    ] if synapse_config.spark_pools != null
  ])

  spark_pools = {
    for spark_pool in local.spark_pool_list : spark_pool.spark_pool_key => spark_pool
  }
}

resource "azurerm_synapse_spark_pool" "spark_pool" {
  for_each                            = local.spark_pools
  name                                = each.value.name
  synapse_workspace_id                = azurerm_synapse_workspace.synapse_workspace[each.value.synapse_key].id
  node_size_family                    = each.value.node_size_family
  node_size                           = each.value.node_size
  cache_size                          = each.value.cache_size
  compute_isolation_enabled           = each.value.compute_isolation_enabled
  dynamic_executor_allocation_enabled = each.value.dynamic_executor_allocation_enabled
  min_executors                       = each.value.min_executors
  max_executors                       = each.value.max_executors

  ## Node count can only be set when auto scale is not configured
  node_count = try(length(each.value.auto_scale), 0) > 0 ? null : each.value.node_count

  spark_log_folder               = each.value.spark_log_folder
  spark_events_folder            = each.value.spark_events_folder
  spark_version                  = each.value.spark_version
  session_level_packages_enabled = each.value.session_level_packages_enabled

  dynamic "auto_scale" {
    for_each = try(length(each.value.auto_scale), 0) > 0 ? [each.value.auto_scale] : []

    content {
      max_node_count = auto_scale.value.max_node_count
      min_node_count = auto_scale.value.min_node_count
    }
  }

  dynamic "auto_pause" {
    for_each = try(length(each.value.auto_pause), 0) > 0 ? [each.value.auto_pause] : []

    content {
      delay_in_minutes = auto_pause.value.delay_in_minutes
    }

  }

  dynamic "library_requirement" {
    for_each = try(length(each.value.library_requirement), 0) > 0 ? [each.value.library_requirement] : []

    content {
      content  = library_requirement.value.content
      filename = library_requirement.value.filename
    }

  }

  dynamic "spark_config" {
    for_each = try(length(each.value.spark_config), 0) > 0 ? [each.value.spark_config] : []

    content {
      content  = spark_config.value.content
      filename = spark_config.value.filename
    }

  }

  tags = each.value.tags

  depends_on = [
    azurerm_synapse_workspace_key.synapse_workspace_key
  ]
}