locals {
  vnet_name                = try(local.app_network.vnet_name, null)
  vnet_resource_group_name = try(local.app_network.vnet_resource_group_name, null)

  vnet_info = local.vnet_name != null && local.vnet_resource_group_name != null ? {
    lower(format("%s/%s", local.vnet_name, local.vnet_resource_group_name)) = {
      resource_key        = lower(format("%s/%s", local.vnet_name, local.vnet_resource_group_name))
      name                = local.vnet_name
      resource_group_name = local.vnet_resource_group_name
    }
  } : {}

  subnets = {
    for subnet in try(local.app_network.subnets, []) : lower(format("%s/%s", local.vnet_name, subnet)) => {
      resource_key         = lower(format("%s/%s", local.vnet_name, subnet))
      name                 = subnet
      virtual_network_name = local.vnet_name
      resource_group_name  = local.vnet_resource_group_name
    }
  }

  #   subnet_virtual_networks = {
  #     for subnet in try(local.global_config.subnets, []) : "${subnet}" => {
  #       name                = local.vnet_name
  #       resource_group_name = local.vnet_resource_group_name
  #     }
  #   }
}

## Get subnet IDs
data "azurerm_subnet" "subnets" {
  for_each             = local.subnets
  name                 = each.value.name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}

locals {
  subnet_ids_by_name = {
    for value in data.azurerm_subnet.subnets : value.name => value.id
  }

  udr_ids_by_subnet_name = {
    for value in data.azurerm_subnet.subnets : value.name => value.route_table_id
  }
}