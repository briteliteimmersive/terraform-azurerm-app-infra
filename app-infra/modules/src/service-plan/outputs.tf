locals {
  service_plan_output_properties = ["id", "name", "resource_group_name", "kind"]
  module_output = {
    for service_plan_key, service_plan_config in azurerm_service_plan.service_plan : "${service_plan_key}" => {
      for key, value in service_plan_config : key => value if contains(local.service_plan_output_properties, key)
    }
  }

}

output "outputs" {
  value = local.module_output
}