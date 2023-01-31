locals {

  workspace_role_assignment_list = flatten([
    for synapse_key, synapse_config in local.synapse_configs : [
      for workspace_role_assignment in synapse_config.workspace_role_assignments : {
        workspace_role_assignment_key = lower(format("%s/%s/%s", synapse_key, workspace_role_assignment.role_name, workspace_role_assignment.object_id))
        synapse_key                   = synapse_key
        role_name                     = workspace_role_assignment.role_name
        principal_id                  = workspace_role_assignment.object_id
      }
    ]
  ])

  workspace_role_assignments = {
    for role_assignment in local.workspace_role_assignment_list : role_assignment.workspace_role_assignment_key => role_assignment
  }
}

resource "azurerm_synapse_role_assignment" "synapse_role_assignment" {
  for_each             = local.workspace_role_assignments
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace[each.value.synapse_key].id
  role_name            = each.value.role_name
  principal_id         = each.value.principal_id
  depends_on = [
    azurerm_synapse_firewall_rule.firewall_rule
  ]
}