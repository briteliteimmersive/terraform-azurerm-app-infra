variable "virtual_machine_configs" {
  type = list(object(
    {
      resource_key                  = string
      hostname                      = string
      resource_group_name           = string
      location                      = string
      size                          = string
      admin_username                = string
      admin_password                = string
      enable_accelerated_networking = bool
      zone                          = number
      ip_configuration = list(object(
        {
          name                          = string
          subnet_id                     = string
          private_ip_address_allocation = string
          private_ip_address            = string
        }
      ))
      os_disk = object(
        {
          caching              = string
          storage_account_type = string
          disk_size_gb         = string
        }
      )
      plan = object(
        {
          name      = string
          product   = string
          publisher = string
        }
      )
      source_image_reference = object(
        {
          publisher = string
          offer     = string
          sku       = string
          version   = string
        }
      )
      datadisks = list(object(
        {
          storage_account_type = string
          disk_size_gb         = string
          caching              = string
          lun                  = number
          zone                 = number
        }
      ))
      boot_diagnostics = object({
        storage_account_uri = string
      })
      sql_extension = object(
        {
          sql_license_type      = string
          r_services_enabled    = bool
          sql_connectivity_port = number
          sql_connectivity_type = string
          role_assignments = list(
            object(
              {
                role_definition_id = string
                object_ids         = list(string)
              }
            )
          )
          tags = map(string)
        }
      )
      role_assignments = list(
        object(
          {
            role_definition_id = string
            object_ids         = list(string)
          }
        )
      )
      tags = map(string)
    }
  ))
}

variable "domain_join" {
  type = object(
    {
      domain_name                          = string
      ou_path                              = string
      user                                 = string
      restart                              = bool
      password                             = string
      options                              = string
      extension_type_handler_version       = string
      extension_auto_upgrade_minor_version = bool
    }
  )
  default = null
}

variable "disk_encryption_set_id" {
  type    = string
  default = null
}

variable "enable_vm_vulnerability_assessment" {
  type = bool
}

variable "backup_settings" {
  type = object(
    {
      recovery_vault_name = string
      resource_group_name = string
      backup_policy_name  = string
    }
  )
  default = null
}

variable "app_key_vault_id" {
  type        = string
  description = "Key vault ID"
}