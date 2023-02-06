locals {

  role_by_linked_service_type = {
    "azurekeyvault" = "Key Vault Secrets User"
  }

  workspace_linked_services_list = flatten([
    for synapse_key, synapse_config in local.synapse_configs : [
      for workspace_linked_service in synapse_config.workspace_linked_services : {
        workspace_linked_services_key = lower(format("%s/%s", synapse_key, workspace_linked_service.name))
        synapse_key                   = synapse_key
        name                          = workspace_linked_service.name
        type                          = workspace_linked_service.type
        type_properties_json          = workspace_linked_service.type_properties_json
        role_name                     = local.role_by_linked_service_type[lower(workspace_linked_service.type)]
        system_identity               = try(length(synapse_config.identity.user_identity_names) == 0, true)
        linked_service_id             = workspace_linked_service.linked_service_id
      }
    ]
  ])

  workspace_linked_service_roles = toset([
    for linked_service in local.workspace_linked_services_list : linked_service.role_name
  ])

  workspace_linked_services = {
    for linked_services in local.workspace_linked_services_list : linked_services.workspace_linked_services_key => linked_services
  }

  workspace_linked_service_role_assignments = {
    for linked_service_key, linked_service in local.workspace_linked_services : linked_service_key => linked_service if linked_service.system_identity
  }

}

data "azurerm_role_definition" "linked_service_role" {
  for_each = local.workspace_linked_service_roles
  name     = each.value
}

resource "azurerm_role_assignment" "sysassigned_linked_svc_role_assignment" {
  for_each           = local.workspace_linked_service_role_assignments
  scope              = each.value.linked_service_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.linked_service_role[each.value.role_name].id)
  principal_id       = azurerm_synapse_workspace.synapse_workspace[each.value.synapse_key].identity[0].principal_id
}

resource "azurerm_synapse_linked_service" "linked_service" {
  for_each             = local.workspace_linked_services
  name                 = each.value.name
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace[each.value.synapse_key].id
  type                 = each.value.type
  type_properties_json = each.value.type_properties_json

  depends_on = [
    azurerm_synapse_firewall_rule.firewall_rule
  ]
}