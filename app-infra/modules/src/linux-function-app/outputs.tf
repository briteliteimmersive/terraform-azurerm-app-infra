locals {
  function_app_output_properties = [
    "id",
    "name",
    "resource_group_name",
    "kind",
    "identity",
    "site_config"
  ]
  module_output = {
    for function_app_key, function_app_config in azurerm_linux_function_app.linux_function_app : "${function_app_key}" => {
      for key, value in function_app_config : key => value if contains(local.function_app_output_properties, key)
    }
  }

}

output "outputs" {
  value = local.module_output
}