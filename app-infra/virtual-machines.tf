variable "linux_vm_configs" {
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
      subnet_name = string
      source_image_reference = optional(object({
        publisher = string
        offer     = string
        sku       = string
        version   = string
        }), {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-focal"
        sku       = "20_04-lts"
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
        tags = optional(map(string))
      }
    ))
  })

  default = null
}

locals {

  linux_vm_inputs              = var.linux_vm_configs
  linux_vm_rgp                 = try(local.linux_vm_inputs.resource_group_name, null)
  linux_vm_diagnostic_settings = try(local.linux_vm_inputs.diagnostic_settings, null)
  linux_vm_role_assignments    = try(local.linux_vm_inputs.role_assignments, [])
  linux_vm_tags                = try(local.linux_vm_inputs.tags, {})
  linux_vm_common_settings     = try(local.linux_vm_inputs.common_vm_settings, null)
  linux_vm_list                = try(local.linux_vm_inputs.vms, [])

  vm_resource_groups = distinct([
    for vm in local.linux_vm_list : {
      name             = coalesce(vm.resource_group_name, local.linux_vm_rgp)
      resource_key     = lower(coalesce(vm.resource_group_name, local.linux_vm_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])

  linux_vm_configs_map = {
    for vm in local.linux_vm_list : vm.hostname => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(vm.resource_group_name, local.linux_vm_rgp),
        vm.hostname
      ))
      resource_group_name = module.resource_groups.outputs[lower(coalesce(vm.resource_group_name, local.linux_vm_rgp))].name
      location            = local.location
      tags = merge(
        local.linux_vm_tags,
        vm.tags,
        local.common_resource_tags
      )
      diagnostic_settings = try(length(local.linux_vm_diagnostic_settings) > 0, false) ? [
        for setting in local.linux_vm_diagnostic_settings.settings : {
          name   = setting.name
          log    = setting.log
          metric = setting.metric
          log_analytics_workspace_name = try(
            local.linux_vm_diagnostic_settings.log_analytics_workspace_name,
            null
          )
          log_analytics_workspace_id = try(
            local.linux_vm_diagnostic_settings.log_analytics_workspace_id,
            # module.log_analytics.outputs[local.linux_vm_diagnostic_settings.log_analytics_workspace_name].id, ## Needs fixing
            null
          )
        }
      ] : []
      role_assignments                = local.linux_vm_role_assignments
      hostname                        = vm.hostname
      admin_username                  = local.admin_username
      admin_password                  = random_password.vm_password["linux"].result
      enable_accelerated_networking   = coalesce(vm.enable_accelerated_networking, local.linux_vm_common_settings.enable_accelerated_networking)
      disable_password_authentication = false
      size                            = coalesce(vm.size, local.linux_vm_common_settings.size)
      zone                            = vm.zone
      boot_diagnostics = {
        storage_account_uri = local.admin_vm_boot_diagnostics_storage_uri
      }
      ip_configuration = [
        {
          name                          = "IPv4-CONFIG"
          subnet_id                     = local.subnet_ids_by_name[coalesce(vm.subnet_name, local.linux_vm_common_settings.subnet_name)]
          private_ip_address_allocation = "Static"
          private_ip_address            = vm.ip_address
        }
      ]
      os_disk = coalesce(vm.os_disk, local.linux_vm_common_settings.os_disk)
      plan    = try(coalesce(vm.plan, local.linux_vm_common_settings.plan), null)
      ## Image id takes preference
      source_image_reference = try(coalesce(vm.source_image_id, local.linux_vm_common_settings.source_image_id), null) == null ? coalesce(
        vm.source_image_reference, local.linux_vm_common_settings.source_image_reference
      ) : null
      source_image_id = try(coalesce(vm.source_image_id, local.linux_vm_common_settings.source_image_id), null)
      datadisks = [
        for disk in coalesce(vm.datadisks, local.linux_vm_common_settings.datadisks) : merge(disk, {
          zone = vm.zone
        })
      ]
    }
  }

  linux_vm_configs = values(local.linux_vm_configs_map)

  loadbalancer_backend_pool_address_list = flatten([
    for vm_details in local.linux_vm_list : [
      {
        name       = vm_details.hostname
        ip_address = vm_details.ip_address
        load_balancer_backend_pool_key = try(
          lower(format("%s/%s/%s",
            vm_details.load_balancing_configuration.lb_resource_group_name,
            vm_details.load_balancing_configuration.lb_name,
            vm_details.load_balancing_configuration.lb_backend_pool_name
          )),
          lower(format("%s/%s/%s",
            coalesce(vm_details.resource_group_name, local.linux_vm_rgp),
            vm_details.load_balancing_configuration.lb_name,
            vm_details.load_balancing_configuration.lb_backend_pool_name
          ))
        )
        virtual_network_id = local.vnet_id
      }
    ] if vm_details.load_balancing_configuration != null
  ])

  distinct_load_balancer_backend_pool_keys = distinct([
    for lb_config in local.loadbalancer_backend_pool_address_list : lb_config.load_balancer_backend_pool_key
  ])

  loadbalancer_backend_pool_address = {
    for pool_key in local.distinct_load_balancer_backend_pool_keys : pool_key => [
      for lb_config in local.loadbalancer_backend_pool_address_list : lb_config if lb_config.load_balancer_backend_pool_key == pool_key
    ]
  }

  ## VM secrets
  username_key = "VM-ADMIN-USERNAME"
  password_key = "VM-ADMIN-PASSWORD"
  linux_vm_secrets = length(var.linux_vm_configs) > 0 ? [
    {
      secret_key   = replace(upper(format("%s-LINUX-%s", local.environment, local.username_key)), " ", "-")
      secret_value = local.admin_username
    },
    {
      secret_key   = replace(upper(format("%s-LINUX-%s", local.environment, local.password_key)), " ", "-")
      secret_value = random_password.vm_password["linux"].result
    }
  ] : []

}

resource "random_password" "vm_password" {
  for_each    = length(var.linux_vm_configs) > 0 ? local.admin_linux_vm_password_policy : {}
  length      = each.value.length
  lower       = each.value.lower
  min_lower   = each.value.min_lower
  min_upper   = each.value.min_upper
  min_numeric = each.value.min_numeric
  min_special = each.value.min_special
}

module "linux_virtual_machine" {
  source                             = "./modules/src/linux-virtual-machine"
  virtual_machine_configs            = local.linux_vm_configs
  enable_vm_vulnerability_assessment = local.linux_vm_common_settings.enable_vm_vulnerability_assessment
  disk_encryption_set_id             = local.admin_disk_encryption_set_id
  backup_settings                    = local.admin_vm_backup_settings
}