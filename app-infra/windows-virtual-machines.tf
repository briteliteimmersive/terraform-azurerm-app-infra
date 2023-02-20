variable "windows_vm_configs" {
  type = object({
    resource_group_name = string
    diagnostic_settings = optional(object(
      {
        log_analytics_workspace_name = optional(string)
        log_analytics_workspace_id   = optional(string)
        settings = list(object(
          {
            name = string
            log = optional(list(object(
              {
                category       = string
                category_group = string
                enabled        = bool
                retention_policy = object(
                  {
                    enabled = bool
                    days    = number
                  }
                )
              }
            )), [])
            metric = optional(list(object(
              {
                category = string
                enabled  = bool
                retention_policy = object(
                  {
                    enabled = bool
                    days    = number
                  }
                )
              }
            )), [])
          }
        ))
      }
    ))
    role_assignments = optional(list(
      object(
        {
          role_definition_id = string
          object_ids         = list(string)
        }
      )
    ), [])
    tags = optional(map(string), {})
    common_vm_settings = object({
      subnet_name    = string
      admin_username = optional(string, "svsupervisor")
      source_image_reference = optional(object({
        publisher = string
        offer     = string
        sku       = string
        version   = string
        }), {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-Datacenter"
        version   = "latest"
      })
      source_image_id = optional(string)
      plan = optional(object({
        name      = string
        product   = string
        publisher = string
      }))
      os_disk = optional(object({
        caching              = optional(string, "ReadWrite")
        storage_account_type = optional(string, "Standard_LRS")
        disk_size_gb         = optional(number)
        }), {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb         = null
      })
      enable_accelerated_networking = optional(bool, false)
      size                          = optional(string, "Standard_D2s_v3")
      datadisks = optional(list(object(
        {
          storage_account_type = optional(string, "Standard_LRS")
          disk_size_gb         = number
          caching              = optional(string, "ReadWrite")
          lun                  = number
        }
      )), [])
      enable_vm_vulnerability_assessment = optional(bool, false)
    })
    vms = list(object(
      {
        hostname                      = string
        ip_address                    = string
        size                          = optional(string)
        enable_accelerated_networking = optional(bool)
        resource_group_name           = optional(string)
        subnet_name                   = optional(string)
        zone                          = optional(string)
        source_image_reference = optional(object({
          publisher = string
          offer     = string
          sku       = string
          version   = string
        }))
        source_image_id = optional(string)
        plan = optional(object({
          name      = string
          product   = string
          publisher = string
        }))
        os_disk = optional(object({
          caching              = optional(string, "ReadWrite")
          storage_account_type = optional(string, "Standard_LRS")
          disk_size_gb         = optional(number)
        }))
        datadisks = optional(list(object(
          {
            storage_account_type = optional(string, "Standard_LRS")
            disk_size_gb         = number
            caching              = optional(string, "ReadWrite")
            lun                  = number
          }
        )))
        load_balancing_configuration = optional(object(
          {
            lb_resource_group_name = optional(string)
            lb_name                = string
            lb_backend_pool_name   = string
          }
        ))
        sql_extension = optional(object(
          {
            sql_license_type      = optional(string, "PAYG")
            r_services_enabled    = optional(bool, false)
            sql_connectivity_port = optional(number, 1433)
            sql_connectivity_type = optional(string, "PRIVATE")
            role_assignments = optional(list(
              object(
                {
                  role_definition_id = string
                  object_ids         = list(string)
                }
              )
            ), [])
            tags = optional(map(string), {})
          }
          ), {
          sql_license_type      = "PAYG"
          r_services_enabled    = false
          sql_connectivity_port = 1433
          sql_connectivity_type = "PRIVATE"
          role_assignments      = []
          tags                  = {}
        })
        tags = optional(map(string))
      }
    ))
  })

  default = null
}

locals {

  windows_vm_inputs              = var.windows_vm_configs
  windows_vm_rgp                 = try(local.windows_vm_inputs.resource_group_name, null)
  windows_vm_diagnostic_settings = try(local.windows_vm_inputs.diagnostic_settings, null)
  windows_vm_role_assignments    = try(local.windows_vm_inputs.role_assignments, [])
  windows_vm_tags                = try(local.windows_vm_inputs.tags, {})
  windows_vm_common_settings     = try(local.windows_vm_inputs.common_vm_settings, null)
  windows_vm_list                = try(local.windows_vm_inputs.vms, [])

  windows_vm_resource_groups = distinct([
    for vm in local.windows_vm_list : {
      name             = coalesce(vm.resource_group_name, local.windows_vm_rgp)
      resource_key     = lower(coalesce(vm.resource_group_name, local.windows_vm_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])

  windows_vm_configs_map = {
    for vm in local.windows_vm_list : vm.hostname => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(vm.resource_group_name, local.windows_vm_rgp),
        vm.hostname
      ))
      resource_group_name = module.resource_groups.outputs[lower(coalesce(vm.resource_group_name, local.windows_vm_rgp))].name
      location            = local.location
      tags = merge(
        local.windows_vm_tags,
        vm.tags,
        local.common_resource_tags
      )
      diagnostic_settings = try(length(local.windows_vm_diagnostic_settings) > 0, false) ? [
        for setting in local.windows_vm_diagnostic_settings.settings : {
          name   = setting.name
          log    = setting.log
          metric = setting.metric
          log_analytics_workspace_name = try(
            local.windows_vm_diagnostic_settings.log_analytics_workspace_name,
            null
          )
          log_analytics_workspace_id = try(
            local.windows_vm_diagnostic_settings.log_analytics_workspace_id,
            # module.log_analytics.outputs[local.windows_vm_diagnostic_settings.log_analytics_workspace_name].id, ## Needs fixing
            null
          )
        }
      ] : []
      role_assignments                = local.windows_vm_role_assignments
      hostname                        = vm.hostname
      admin_username                  = local.windows_vm_common_settings.admin_username
      admin_password                  = random_password.win_vm_password["windows"].result
      enable_accelerated_networking   = coalesce(vm.enable_accelerated_networking, local.windows_vm_common_settings.enable_accelerated_networking)
      disable_password_authentication = false
      size                            = coalesce(vm.size, local.windows_vm_common_settings.size)
      zone                            = vm.zone
      boot_diagnostics = {
        storage_account_uri = local.admin_vm_boot_diagnostics_storage_uri
      }
      ip_configuration = [
        {
          name                          = "IPv4-CONFIG"
          subnet_id                     = local.subnet_ids_by_name[coalesce(vm.subnet_name, local.windows_vm_common_settings.subnet_name)]
          private_ip_address_allocation = "Static"
          private_ip_address            = vm.ip_address
        }
      ]
      os_disk = coalesce(vm.os_disk, local.windows_vm_common_settings.os_disk)
      plan    = try(coalesce(vm.plan, local.windows_vm_common_settings.plan), null)
      ## Image id takes preference
      source_image_reference = try(coalesce(vm.source_image_id, local.windows_vm_common_settings.source_image_id), null) == null ? coalesce(
        vm.source_image_reference, local.windows_vm_common_settings.source_image_reference
      ) : null
      source_image_id = try(coalesce(vm.source_image_id, local.windows_vm_common_settings.source_image_id), null)
      datadisks = [
        for disk in coalesce(vm.datadisks, local.windows_vm_common_settings.datadisks) : merge(disk, {
          zone = vm.zone
        })
      ]

      sql_extension = try(lower(coalesce(vm.source_image_reference.publisher, local.windows_vm_common_settings.source_image_reference.publisher)) == "microsoftsqlserver", false) ? merge(vm.sql_extension, {
        tags = merge(local.windows_vm_tags, vm.tags, local.common_resource_tags)
      }) : null
    }
  }

  windows_vm_configs = values(local.windows_vm_configs_map)

}

resource "random_password" "win_vm_password" {
  for_each    = try(length(var.windows_vm_configs) > 0, false) ? local.admin_windows_vm_password_policy : {}
  length      = each.value.length
  lower       = each.value.lower
  min_lower   = each.value.min_lower
  min_upper   = each.value.min_upper
  min_numeric = each.value.min_numeric
  min_special = each.value.min_special
}

module "windows_virtual_machine" {
  source                             = "./modules/src/windows-virtual-machine"
  virtual_machine_configs            = local.windows_vm_configs
  enable_vm_vulnerability_assessment = local.enable_vm_vulnerability_assessment
  disk_encryption_set_id             = local.admin_disk_encryption_set_id
  backup_settings                    = local.admin_vm_backup_settings
  app_key_vault_id                   = local.infra_keyvault_id
}