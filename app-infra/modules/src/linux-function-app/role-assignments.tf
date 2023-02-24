locals {
  user_role_assignment_list = flatten([
    for resource_key, resource_config in local.linux_function_app_configs :
    [
      for role_assignment in resource_config.role_assignments : [
        for object_id in role_assignment.object_ids : [
          {
            role_assignment_key = lower(format("%s/%s/%s", resource_key, role_assignment.role_definition_id, object_id))
            role_definition_id  = format("/subscriptions/%s/providers/Microsoft.Authorization/roleDefinitions/%s", data.azurerm_client_config.current.subscription_id, role_assignment.role_definition_id)
            principal_id        = object_id
            resource_key        = resource_key
          }
        ]
      ]
    ]
    ]
  )

  role_assignments = {
    for role_assignment in local.user_role_assignment_list : role_assignment.role_assignment_key => role_assignment
  }
}

resource "azurerm_role_assignment" "user_role_assignment" {
  for_each           = local.role_assignments
  scope              = azurerm_linux_function_app.linux_function_app[each.value.resource_key].id
  role_definition_id = each.value.role_definition_id
  principal_id       = each.value.principal_id
}