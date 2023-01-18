locals {
  aks_output_properties = ["id", "name", "resource_group_name", "fqdn", "node_resource_group", "api_server_authorized_ip_ranges"]
  module_output = {
    for aks_key, aks_config in azurerm_kubernetes_cluster.aks_cluster : "${aks_key}" => {
      for key, value in aks_config : key => value if contains(local.aks_output_properties, key)
    }
  }

  aks_sensitive_properties = ["name", "kube_admin_config", "kube_config", "kubelet_identity"]
  sensitive_output = {
    for aks_key, aks_config in azurerm_kubernetes_cluster.aks_cluster : "${aks_key}" => {
      for key, value in aks_config : key => value if contains(local.aks_sensitive_properties, key)
    }
  }

  aks_identity_output = {
    for aks_key, aks_config in azurerm_kubernetes_cluster.aks_cluster : aks_key => [aks_config.kubelet_identity[0].object_id]
  }

}

output "outputs" {
  value = local.module_output
}

output "sensitive_outputs" {
  value     = local.sensitive_output
  sensitive = true
}

output "aks_identities" {
  value = local.aks_identity_output
}