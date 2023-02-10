variable "admin_configs" {
  type = object(
    {
      resource_group_name              = string
      admin_key_vault_name             = string
      vm_boot_diagnostics_storage_name = string
      disk_encryption_set_name         = string
      backup_recovery_vault_name       = string
      vm_backup_policy_name            = string
    }
  )
}

locals {

  admin_rgp                 = var.admin_configs.resource_group_name
  admin_key_vault_name      = var.admin_configs.admin_key_vault_name
  admin_backup_vault        = var.admin_configs.backup_recovery_vault_name
  admin_vm_backup_policy    = var.admin_configs.vm_backup_policy_name
  admin_vm_boot_diagnostics = var.admin_configs.vm_boot_diagnostics_storage_name
  admin_disk_encryption_set = var.admin_configs.disk_encryption_set_name

  admin_key_vault_id = format(
    "/subscriptions/%s/resourceGroups/%s/providers/Microsoft.KeyVault/vaults/%s",
    local.subscription_id,
    local.admin_rgp,
    local.admin_key_vault_name
  )

  admin_disk_encryption_set_id = format(
    "/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Compute/diskEncryptionSets/%s",
    local.subscription_id,
    local.admin_rgp,
    local.admin_disk_encryption_set
  )

  admin_vm_boot_diagnostics_storage_uri = format("https://%s.blob.core.windows.net/", local.admin_vm_boot_diagnostics)

  admin_vm_backup_settings = {
    recovery_vault_name = local.admin_backup_vault
    resource_group_name = local.admin_rgp
    backup_policy_name  = local.admin_vm_backup_policy
  }

  admin_username = "svsupervisor"

  admin_linux_vm_password_policy = {
    "linux" = {
      length      = 16
      lower       = true
      min_lower   = 1
      min_upper   = 2
      min_numeric = 1
      min_special = 1
    }
  }

}