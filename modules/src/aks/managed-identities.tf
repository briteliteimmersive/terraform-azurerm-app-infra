### AKS User Managed Identities
locals {
  aks_with_identities = {
    for aks_key, aks_config in local.aks_configs : aks_key => aks_config if aks_config.identity != null
  }

  aks_with_user_identities = {
    for aks_key, aks_config in local.aks_with_identities : aks_key => aks_config if aks_config.identity.type == "UserAssigned"
  }

  aks_identity_list = flatten([
    for aks_key, aks_config in local.aks_with_user_identities : [
      for aks_identity in aks_config.identity.user_identity_names : {
        identity_key        = "${aks_key}_${aks_identity}"
        name                = aks_identity
        resource_group_name = aks_config.resource_group_name
        location            = aks_config.location
        tags                = aks_config.tags
        aks_key             = aks_key
      }
    ]
  ])

  aks_identities = {
    for identity in local.aks_identity_list : identity.identity_key => identity
  }

  aks_role_assignment_list = flatten([
    for aks_key, aks_config in local.aks_with_user_identities : [
      for aks_identity in aks_config.identity.user_identity_names : {
        identity_key           = "${aks_key}_${aks_identity}"
        aks_key                = aks_key
        route_table_id         = aks_config.route_table_id
        vnet_subnet_id         = aks_config.vnet_subnet_id
        disk_encryption_set_id = aks_config.disk_encryption_set_id
      }
    ]
  ])

  aks_role_assignments = {
    for role_assignment in local.aks_role_assignment_list : role_assignment.identity_key => role_assignment
  }

  aks_udr_role_assignment = {
    for role_assignment in local.aks_role_assignment_list : role_assignment.identity_key => role_assignment if role_assignment.route_table_id != null
  }

  aks_subnet_role_assignment = {
    for role_assignment in local.aks_role_assignment_list : role_assignment.identity_key => role_assignment if role_assignment.vnet_subnet_id != null
  }
}

resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  for_each            = local.aks_identities
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location
  tags                = each.value.tags
}

data "azurerm_role_definition" "network_contributor_builtin_role" {
  name = "Network Contributor"
}

data "azurerm_client_config" "current" {
}
### AKS User Managed Identity role assignment
resource "azurerm_role_assignment" "user_identity_udr_role_assignment" {
  for_each           = local.aks_udr_role_assignment
  scope              = each.value.route_table_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.network_contributor_builtin_role.id)
  principal_id       = azurerm_user_assigned_identity.user_assigned_identity[each.key].principal_id
}

resource "azurerm_role_assignment" "user_identity_subnet_role_assignment" {
  for_each           = local.aks_subnet_role_assignment
  scope              = each.value.vnet_subnet_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.network_contributor_builtin_role.id)
  principal_id       = azurerm_user_assigned_identity.user_assigned_identity[each.key].principal_id
}

### For contributor on disk encryption set
data "azurerm_role_definition" "contributor_builtin_role" {
  name = "Contributor"
}

resource "azurerm_role_assignment" "user_identity_disk_encryption_role_assignment" {
  for_each           = local.aks_role_assignments
  scope              = each.value.disk_encryption_set_id
  role_definition_id = format("/subscriptions/%s%s", data.azurerm_client_config.current.subscription_id, data.azurerm_role_definition.contributor_builtin_role.id)
  principal_id       = azurerm_user_assigned_identity.user_assigned_identity[each.key].principal_id
}