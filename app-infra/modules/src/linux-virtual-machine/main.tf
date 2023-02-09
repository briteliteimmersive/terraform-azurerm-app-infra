locals {
  osdisk_identifier   = "osdk01"
  nic_identifier      = "nic01"
  datadisk_identifier = "dsdk"

  virtual_machine_configs = var.virtual_machine_configs

  disk_encryption_set_id = var.disk_encryption_set_id

  vms = {
    for vm in local.virtual_machine_configs : vm.resource_key => vm
  }

}


resource "azurerm_network_interface" "vm_network_interface" {
  for_each            = local.vms
  name                = format("%s-%s", each.value.hostname, local.nic_identifier)
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  dynamic "ip_configuration" {
    for_each = each.value.ip_configuration
    content {
      name                          = ip_configuration.value.name
      subnet_id                     = ip_configuration.value.subnet_id
      private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
      private_ip_address            = ip_configuration.value.private_ip_address
    }
  }

  enable_accelerated_networking = each.value.enable_accelerated_networking
  tags                          = each.value.tags
}

resource "time_sleep" "nic_resource_propagation" {
  for_each        = local.vms
  create_duration = "2s"

  triggers = {
    vm_nic_id = azurerm_network_interface.vm_network_interface[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  for_each                        = local.vms
  name                            = each.value.hostname
  admin_username                  = each.value.admin_username
  admin_password                  = each.value.admin_password
  location                        = each.value.location
  resource_group_name             = each.value.resource_group_name
  size                            = each.value.size
  network_interface_ids           = [time_sleep.nic_resource_propagation[each.key].triggers["vm_nic_id"]]
  disable_password_authentication = each.value.disable_password_authentication
  zone                            = each.value.zone

  os_disk {
    caching                = each.value.os_disk.caching
    disk_size_gb           = each.value.os_disk.disk_size_gb
    name                   = format("%s-%s", each.value.hostname, local.osdisk_identifier)
    storage_account_type   = each.value.os_disk.storage_account_type
    disk_encryption_set_id = local.disk_encryption_set_id
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  dynamic "plan" {
    for_each = each.value.plan != null ? [each.value.plan] : []
    content {
      name      = plan.value.name
      product   = plan.value.product
      publisher = plan.value.publisher
    }
  }

  dynamic "boot_diagnostics" {
    for_each = each.value.boot_diagnostics != null ? [each.value.boot_diagnostics] : []
    content {
      storage_account_uri = boot_diagnostics.value.storage_account_uri
    }
  }

  tags = each.value.tags
}

## Data disks
locals {
  datadisks_by_vms = {
    for vm_key, vm in local.vms : vm_key => vm.datadisks
  }

  datadisk_list = flatten([
    for vm_key, datadisks in local.datadisks_by_vms :
    [
      for datadisk in datadisks :
      merge({
        datadisk_key = format("%s/%s", vm_key, tostring(datadisk.lun + 1)),
        vm_key       = vm_key
  }, datadisk)]])

  datadisks = { for datadisk_key, datadisk in local.datadisk_list : datadisk.datadisk_key => datadisk }

}

resource "azurerm_managed_disk" "datadisk" {
  for_each               = local.datadisks
  name                   = format("%s-%s%s", azurerm_linux_virtual_machine.linux_vm[each.value.vm_key].name, local.datadisk_identifier, each.value.lun + 1)
  location               = azurerm_linux_virtual_machine.linux_vm[each.value.vm_key].location
  resource_group_name    = azurerm_linux_virtual_machine.linux_vm[each.value.vm_key].resource_group_name
  storage_account_type   = each.value.storage_account_type
  disk_size_gb           = each.value.disk_size_gb
  zone                   = each.value.zone ##try(length(azurerm_linux_virtual_machine.linux_vm[each.value.vm_key].zone) > 0, false) ? azurerm_linux_virtual_machine.linux_vm[each.value.vm_key].zone : null
  disk_encryption_set_id = local.disk_encryption_set_id
  create_option          = "Empty"
  tags                   = azurerm_linux_virtual_machine.linux_vm[each.value.vm_key].tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm_datadisk_attachment" {
  for_each           = local.datadisks
  managed_disk_id    = azurerm_managed_disk.datadisk[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.linux_vm[each.value.vm_key].id
  lun                = each.value.lun
  caching            = each.value.caching
}

resource "time_sleep" "vm_resource_propagation" {
  for_each        = local.vms
  create_duration = "60s"

  triggers = {
    vm_id = azurerm_linux_virtual_machine.linux_vm[each.key].id
  }
}


resource "azurerm_security_center_server_vulnerability_assessment_virtual_machine" "microsoft_defender_vulnerability_assessment" {
  for_each           = var.enable_vm_vulnerability_assessment ? local.vms : {}
  virtual_machine_id = time_sleep.vm_resource_propagation[each.key].triggers["vm_id"]
}

## Configure VM backup
locals {
  backup_settings = var.backup_settings != null ? {
    "backup_settings" = var.backup_settings
  } : {}

  vm_backups = length(local.backup_settings) > 0 ? toset([
    for vm_key, vm in local.vms : vm_key
  ]) : toset([])
}

data "azurerm_backup_policy_vm" "vm_backup_policy" {
  for_each            = local.backup_settings
  name                = each.value.backup_policy_name
  recovery_vault_name = each.value.recovery_vault_name
  resource_group_name = each.value.resource_group_name
}

resource "azurerm_backup_protected_vm" "vm_backup" {
  for_each            = local.vm_backups
  resource_group_name = data.azurerm_backup_policy_vm.vm_backup_policy["backup_settings"].resource_group_name
  recovery_vault_name = data.azurerm_backup_policy_vm.vm_backup_policy["backup_settings"].recovery_vault_name
  source_vm_id        = azurerm_linux_virtual_machine.linux_vm[each.value].id
  backup_policy_id    = data.azurerm_backup_policy_vm.vm_backup_policy["backup_settings"].id
}
