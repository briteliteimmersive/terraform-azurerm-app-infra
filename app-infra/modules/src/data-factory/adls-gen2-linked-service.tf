##Initialize azurerm_data_factory_linked_service_key_vault
locals {
  data_factory_adls_gen2_linked_services_list = flatten([
    for adf_key, adf_config in local.data_factory_configs : [
      for linked_service in adf_config.adls_gen2_linked_services : merge(linked_service, {
        linked_service_key = lower(format("%s/adls-gen2-linked-svc/%s", adf_key, linked_service.name))
        adf_key            = adf_key
      })
    ]
  ])

  data_factory_adls_gen2_linked_services = {
    for linked_service_config in local.data_factory_adls_gen2_linked_services_list : linked_service_config.linked_service_key => linked_service_config
  }
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "adf_linked_adls_gen2" {
  for_each                 = local.data_factory_adls_gen2_linked_services
  name                     = each.value.name
  data_factory_id          = azurerm_data_factory.data_factory[each.value.adf_key].id
  url                      = each.value.url
  description              = each.value.description
  integration_runtime_name = each.value.integration_runtime_name
  annotations              = each.value.annotations
  parameters               = each.value.parameters
  additional_properties    = each.value.additional_properties
  use_managed_identity     = true
}