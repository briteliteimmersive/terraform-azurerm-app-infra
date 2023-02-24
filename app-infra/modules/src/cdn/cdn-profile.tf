locals {
  cdn_configs = {
    for cdn_config in var.cdn_configs : cdn_config.resource_key => cdn_config
  }
}

resource "azurerm_cdn_profile" "cdn_profile" {
  for_each            = local.cdn_configs
  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  sku                 = each.value.sku
  tags                = each.value.tags
}