locals {

  resource_group_config = tolist(toset(concat(
    local.mssql_server_resource_groups,
    local.keyvault_resource_groups,
    local.storage_resource_groups
  )))

}

module "resource_groups" {
  source                = "./modules/src/resource-group"
  resource_group_config = local.resource_group_config
}

output "resource_groups" {
  value = module.resource_groups.outputs
}