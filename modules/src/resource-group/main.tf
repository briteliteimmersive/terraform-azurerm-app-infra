locals {
  resource_group_config = {
    for resource_group in var.resource_group_config : resource_group.resource_key => resource_group
  }
}

resource "azurerm_resource_group" "resource_grp" {
  for_each = local.resource_group_config
  name     = each.value.name
  location = each.value.location
  tags     = each.value.tags
}

resource "time_sleep" "wait_seconds" {
  depends_on      = [azurerm_resource_group.resource_grp]
  create_duration = "5s"
}