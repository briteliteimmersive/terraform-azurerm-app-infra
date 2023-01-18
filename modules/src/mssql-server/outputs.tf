locals {
  mssql_server_output_properties = ["id", "name", "resource_group_name", "fully_qualified_domain_name"]
  module_output = {
    for mssql_server_key, mssql_server_config in azurerm_mssql_server.sql_server : "${mssql_server_key}" => {
      for key, value in mssql_server_config : key => value if contains(local.mssql_server_output_properties, key)
    }
  }

}

output "outputs" {
  value = local.module_output
}