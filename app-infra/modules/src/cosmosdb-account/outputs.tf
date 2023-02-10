locals {
  cosmos_db_output_properties = ["id", "name", "resource_group_name", "endpoint", "read_endpoints", "write_endpoints"]
  module_output = {
    for cosmos_db_key, cosmos_db_config in azurerm_cosmosdb_account.cosmosdb_account : "${cosmos_db_key}" => {
      for key, value in cosmos_db_config : key => value if contains(local.cosmos_db_output_properties, key)
    }
  }

  cosmos_db_sensitive_properties = ["name", "primary_key", "secondary_key", "connection_strings"]
  sensitive_output = {
    for cosmos_db_key, cosmos_db_config in azurerm_cosmosdb_account.cosmosdb_account : "${cosmos_db_key}" => {
      for key, value in cosmos_db_config : key => value if contains(local.cosmos_db_sensitive_properties, key)
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