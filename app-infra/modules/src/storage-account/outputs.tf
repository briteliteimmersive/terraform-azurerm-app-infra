locals {
  storageaccount_output_properties = [
    "id",
    "name",
    "primary_location",
    "secondary_location",
    "primary_blob_endpoint",
    "primary_blob_host",
    "secondary_blob_endpoint",
    "secondary_blob_host",
    "primary_queue_endpoint",
    "primary_queue_host",
    "secondary_queue_endpoint",
    "secondary_queue_host",
    "primary_table_endpoint",
    "primary_table_host",
    "secondary_table_endpoint",
    "secondary_table_host",
    "primary_file_endpoint",
    "primary_file_host ",
    "secondary_file_endpoint ",
    "secondary_file_host",
    "primary_dfs_endpoint",
    "primary_dfs_host",
    "secondary_dfs_endpoint",
    "secondary_dfs_host",
    "primary_web_endpoint",
    "primary_web_host",
    "secondary_web_endpoint",
    "secondary_web_host"
  ]

  module_output = {
    for storageaccount_key, storage_config in azurerm_storage_account.storage_account : "${storageaccount_key}" => merge({
      for key, value in storage_config : key => value if contains(local.storageaccount_output_properties, key)
      }, {
      "primary_connection_string_keyvault_id" = azurerm_key_vault_secret.sa_primary_connection_string[storageaccount_key].id
    })
  }

  storage_acc_sensitive_properties = [
    "name",
    "primary_file_host",
    "secondary_file_host",
    "primary_access_key",
    "secondary_access_key",
    "primary_connection_string",
    "secondary_connection_string",
    "primary_blob_connection_string",
    "secondary_blob_connection_string"
  ]

  sensitive_output = {
    for storageaccount_key, storage_acc_config in azurerm_storage_account.storage_account : "${storageaccount_key}" => {
      for key, value in storage_acc_config : key => value if contains(local.storage_acc_sensitive_properties, key)
    }
  }
}


output "outputs" {
  value = local.module_output
}

output "sensitive_outputs" {
  value     = local.sensitive_output
  sensitive = true
}