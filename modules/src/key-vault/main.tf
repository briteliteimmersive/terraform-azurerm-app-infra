locals {
  key_vault_configs = {
    for key_vault_config in var.keyvault_configs : key_vault_config.resource_key => key_vault_config
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "key_vault" {
  for_each                        = local.key_vault_configs
  name                            = each.value.name
  location                        = each.value.location
  resource_group_name             = each.value.resource_group_name
  sku_name                        = each.value.sku_name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_deployment          = each.value.enabled_for_deployment
  enabled_for_disk_encryption     = each.value.enabled_for_disk_encryption
  enabled_for_template_deployment = each.value.enabled_for_disk_encryption
  enable_rbac_authorization       = each.value.enable_rbac_authorization
  purge_protection_enabled        = each.value.purge_protection_enabled
  soft_delete_retention_days      = each.value.soft_delete_retention_days

  dynamic "network_acls" {
    for_each = each.value.network_acls != null ? [each.value.network_acls] : []
    content {
      bypass                     = network_acls.value.bypass
      default_action             = network_acls.value.default_action
      ip_rules                   = network_acls.value.ip_rules
      virtual_network_subnet_ids = network_acls.value.virtual_network_subnet_ids
    }
  }
  tags = each.value.tags
}