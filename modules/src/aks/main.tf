locals {
  aks_configs = {
    for aks_config in var.aks_configs : aks_config.resource_key => aks_config
  }
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  for_each                          = local.aks_configs
  name                              = each.value.name
  location                          = each.value.location
  resource_group_name               = each.value.resource_group_name
  dns_prefix                        = each.value.dns_prefix
  automatic_channel_upgrade         = each.value.automatic_channel_upgrade
  sku_tier                          = each.value.sku_tier
  api_server_authorized_ip_ranges   = each.value.api_server_authorized_ip_ranges
  disk_encryption_set_id            = each.value.disk_encryption_set_id
  role_based_access_control_enabled = each.value.role_based_access_control_enabled
  http_application_routing_enabled  = each.value.http_application_routing_enabled
  kubernetes_version                = each.value.kubernetes_version

  default_node_pool {
    name                 = each.value.default_node_pool.name
    vm_size              = each.value.default_node_pool.vm_size
    enable_auto_scaling  = each.value.default_node_pool.enable_auto_scaling
    min_count            = each.value.default_node_pool.min_count
    max_count            = each.value.default_node_pool.max_count
    vnet_subnet_id       = each.value.vnet_subnet_id
    orchestrator_version = each.value.default_node_pool.orchestrator_version
    node_labels          = each.value.default_node_pool.node_labels
    tags                 = each.value.tags
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type = identity.value.type
      identity_ids = identity.value.type != "SystemAssigned" ? flatten([
        for identity in identity.value.user_identity_names : [
          azurerm_user_assigned_identity.user_assigned_identity["${each.key}_${identity}"].id
        ]
      ]) : null
    }
  }

  dynamic "network_profile" {
    for_each = try(length(each.value.network_profile), 0) > 0 ? [each.value.network_profile] : []

    content {
      network_plugin     = network_profile.value.network_plugin
      outbound_type      = network_profile.value.outbound_type
      network_policy     = network_profile.value.network_policy
      dns_service_ip     = network_profile.value.dns_service_ip
      docker_bridge_cidr = network_profile.value.docker_bridge_cidr
      pod_cidr           = network_profile.value.pod_cidr
      service_cidr       = network_profile.value.service_cidr
    }
  }

  dynamic "oms_agent" {
    for_each = each.value.oms_agent != null ? [each.value.oms_agent] : []
    content {
      log_analytics_workspace_id = oms_agent.value.log_analytics_workspace_id
    }
  }

  tags = each.value.tags

  depends_on = [
    azurerm_role_assignment.user_identity_udr_role_assignment,
    azurerm_role_assignment.user_identity_subnet_role_assignment
  ]

  lifecycle {
    ignore_changes = [
      default_node_pool.0.tags
    ]
  }

}

locals {
  ## Form user node pool object for each cluster
  user_node_pool_list = flatten([
    for aks_config in var.aks_configs : [
      for nodepool_info in coalesce(aks_config.user_node_pools, []) : {
        name                 = nodepool_info.name
        mode                 = try(nodepool_info.mode, "User")
        cluster_key          = "${aks_config.resource_group_name}_${aks_config.name}"
        nodepool_key         = format("%s_%s", "${aks_config.resource_group_name}_${aks_config.name}", nodepool_info.name)
        vm_size              = nodepool_info.vm_size
        orchestrator_version = nodepool_info.orchestrator_version
        os_disk_size_gb      = nodepool_info.os_disk_size_gb
        os_disk_type         = coalesce(nodepool_info.os_disk_type, "Managed")
        min_count            = nodepool_info.min_count
        max_count            = nodepool_info.max_count
        enable_auto_scaling  = nodepool_info.enable_auto_scaling
        node_labels          = nodepool_info.node_labels
        node_taints          = nodepool_info.node_taints
        max_pods             = nodepool_info.max_pods
        tags                 = aks_config.tags
      }
    ]
  ])

  user_node_pools = {
    for user_nodepool in local.user_node_pool_list : user_nodepool.nodepool_key => user_nodepool
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "user_nodepool" {
  for_each              = local.user_node_pools
  name                  = each.value.name
  mode                  = each.value.mode
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster[each.value.cluster_key].id
  orchestrator_version  = each.value.orchestrator_version
  vm_size               = each.value.vm_size
  os_disk_size_gb       = each.value.os_disk_size_gb
  os_disk_type          = each.value.os_disk_type
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  vnet_subnet_id        = local.aks_configs[each.value.cluster_key].vnet_subnet_id
  enable_auto_scaling   = each.value.enable_auto_scaling
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
  tags                  = each.value.tags
}

### Access to Admin Keyvault for encryption
locals {
  aks_with_disk_encryption = {
    for aks_key, aks in local.aks_configs : aks_key => aks if aks.disk_encryption_set_id != null
  }

  aks_user_identity_kv_assignment_list = flatten([
    for aks_key, aks_config in local.aks_with_disk_encryption : [
      for aks_identity in local.aks_identities : {
        identity_principal_id = azurerm_user_assigned_identity.user_assigned_identity[aks_identity.identity_key].principal_id
      } if aks_identity.aks_key == aks_key
    ]
  ])

  aks_system_identity_kv_assignment_list = flatten([
    for aks_key, aks_config in local.aks_with_disk_encryption : [
      for aks_identity in azurerm_kubernetes_cluster.aks_cluster[aks_key].identity : {
        identity_principal_id = aks_identity.principal_id
      } if aks_identity.type == "SystemAssigned"
    ]
  ])

  aks_identity_kv_assignments = {
    for k, v in concat(local.aks_user_identity_kv_assignment_list, local.aks_system_identity_kv_assignment_list) : k => v
  }

  admin_key_vault_id = var.admin_key_vault_id
}

data "azurerm_role_definition" "kv_builtin_role" {
  name = "Key Vault Crypto Service Encryption User"
}

resource "azurerm_role_assignment" "aks_identity_kv_role_assignment" {
  for_each           = local.admin_key_vault_id != null ? local.aks_identity_kv_assignments : {}
  scope              = local.admin_key_vault_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.kv_builtin_role.id)
  principal_id       = each.value.identity_principal_id
}

resource "azurerm_role_assignment" "aks_identity_kv_role_assignment_app_kv" {
  for_each           = local.aks_identity_kv_assignments
  scope              = local.app_key_vault_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.kv_builtin_role.id)
  principal_id       = each.value.identity_principal_id
}