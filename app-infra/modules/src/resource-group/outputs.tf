locals {
  rgp_output_properties = ["id", "name", "location"]
  module_output = {
    for rgp_key, rgp_config in azurerm_resource_group.resource_grp : "${rgp_key}" => {
      for key, value in rgp_config : key => value if contains(local.rgp_output_properties, key)
    }
  }
}

output "outputs" {
  value = azurerm_resource_group.resource_grp
}

output "wait_output" {
  value = time_sleep.wait_seconds
}