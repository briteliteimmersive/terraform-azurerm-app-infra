locals {

  sql_password_policy = {
    length      = 16
    lower       = true
    min_lower   = 1
    min_upper   = 2
    min_numeric = 1
    min_special = 1
  }

  sql_vms = {
    for vm_key, vm in local.vms : vm_key => {
      sql_connectivity_update_username = lower(format("%s-sqladmin", vm.hostname))
      sql_license_type                 = vm.sql_extension.sql_license_type
      r_services_enabled               = vm.sql_extension.r_services_enabled
      sql_connectivity_port            = vm.sql_extension.sql_connectivity_port
      sql_connectivity_type            = vm.sql_extension.sql_connectivity_type
      role_assignments                 = vm.sql_extension.role_assignments
      tags                             = vm.sql_extension.tags
      password_policy                  = local.sql_password_policy
      vm_name                          = vm.hostname
    } if vm.sql_extension != null
  }

}


resource "random_password" "sql_password" {
  for_each    = local.sql_vms
  length      = each.value.password_policy.length
  lower       = each.value.password_policy.lower
  min_lower   = each.value.password_policy.min_lower
  min_upper   = each.value.password_policy.min_upper
  min_numeric = each.value.password_policy.min_numeric
  min_special = each.value.password_policy.min_special
}

resource "azurerm_mssql_virtual_machine" "sql_extension" {
  for_each                         = local.sql_vms
  virtual_machine_id               = time_sleep.vm_domain_join_resource_propagation[each.key].triggers["vm_id"]
  sql_license_type                 = each.value.sql_license_type
  r_services_enabled               = each.value.r_services_enabled
  sql_connectivity_port            = each.value.sql_connectivity_port
  sql_connectivity_type            = each.value.sql_connectivity_type
  sql_connectivity_update_password = random_password.sql_password[each.key].result
  sql_connectivity_update_username = each.value.sql_connectivity_update_username
  tags                             = each.value.tags

  lifecycle {
    ignore_changes = [
      auto_backup,
      auto_patching,
      key_vault_credential,
      storage_configuration
    ]
  }
}