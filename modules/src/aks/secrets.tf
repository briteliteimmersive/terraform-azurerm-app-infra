locals {
  app_key_vault_id = var.app_key_vault_id
}

resource "azurerm_key_vault_secret" "kubelet_client_id" {
  for_each     = local.aks_configs
  name         = upper(replace(format("%s-kubelet-clientid", each.value.name), "_", "-"))
  value        = azurerm_kubernetes_cluster.aks_cluster[each.key].kubelet_identity[0].client_id
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "kubelet_object_id" {
  for_each     = local.aks_configs
  name         = upper(replace(format("%s-kubelet-objectid", each.value.name), "_", "-"))
  value        = azurerm_kubernetes_cluster.aks_cluster[each.key].kubelet_identity[0].object_id
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "kube_config_client_key" {
  for_each     = local.aks_configs
  name         = upper(replace(format("%s-kube-config-clientkey", each.value.name), "_", "-"))
  value        = azurerm_kubernetes_cluster.aks_cluster[each.key].kube_config[0].client_key
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "kube_client_certificate" {
  for_each     = local.aks_configs
  name         = upper(replace(format("%s-kube-config-client-certificate", each.value.name), "_", "-"))
  value        = azurerm_kubernetes_cluster.aks_cluster[each.key].kube_config[0].client_certificate
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "kube_cluster_ca_certificate" {
  for_each     = local.aks_configs
  name         = upper(replace(format("%s-kube-config-cluster-ca-certificate", each.value.name), "_", "-"))
  value        = azurerm_kubernetes_cluster.aks_cluster[each.key].kube_config[0].cluster_ca_certificate
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "kube_username" {
  for_each     = local.aks_configs
  name         = upper(replace(format("%s-kube-config-username", each.value.name), "_", "-"))
  value        = azurerm_kubernetes_cluster.aks_cluster[each.key].kube_config[0].username
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "kube_password" {
  for_each     = local.aks_configs
  name         = upper(replace(format("%s-kube-config-password", each.value.name), "_", "-"))
  value        = azurerm_kubernetes_cluster.aks_cluster[each.key].kube_config[0].password
  key_vault_id = local.app_key_vault_id
}

resource "azurerm_key_vault_secret" "kube_host" {
  for_each     = local.aks_configs
  name         = upper(replace(format("%s-kube-host", each.value.name), "_", "-"))
  value        = azurerm_kubernetes_cluster.aks_cluster[each.key].kube_config[0].host
  key_vault_id = local.app_key_vault_id
}