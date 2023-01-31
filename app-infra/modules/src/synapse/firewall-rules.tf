locals {

  firewall_rules_list = flatten([
    for synapse_key, synapse_config in local.synapse_configs : [
      for firewall_rule in synapse_config.firewall_rules : {
        firewall_rules_key = lower(format("%s/%s", synapse_key, firewall_rule.name))
        synapse_key        = synapse_key
        name               = firewall_rule.name
        start_ip_address   = firewall_rule.start_ip_address
        end_ip_address     = firewall_rule.end_ip_address
      }
    ]
  ])

  firewall_rules = {
    for firewall_rule in local.firewall_rules_list : firewall_rule.firewall_rules_key => firewall_rule
  }
}

resource "azurerm_synapse_firewall_rule" "firewall_rule" {
  for_each             = local.firewall_rules
  name                 = each.value.name
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace[each.value.synapse_key].id
  start_ip_address     = each.value.start_ip_address
  end_ip_address       = each.value.end_ip_address
}