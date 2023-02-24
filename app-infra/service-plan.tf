locals {
  ## Service plans
  service_plan_configs_map = merge(
    {
      ## Linux Apps Service Plans
      for app_service_config in local.linux_apps_list : app_service_config.service_plan.name => merge(app_service_config.service_plan, {
        resource_group_name        = module.resource_groups.outputs[coalesce(app_service_config.resource_group_name, local.linux_apps_rgp)].name
        resource_key               = lower(format("%s/%s", coalesce(app_service_config.resource_group_name, local.linux_apps_rgp), app_service_config.service_plan.name))
        location                   = local.location
        os_type                    = "Linux"
        role_assignments           = local.linux_apps_role_assignments
        tags                       = merge(app_service_config.service_plan.tags, local.linux_apps_tags, local.common_resource_tags)
        app_service_environment_id = null
        diagnostic_settings        = local.linux_apps_diagnostic_settings
      })
    }
  )

  service_plan_configs = values(local.service_plan_configs_map)
}

module "service_plan" {
  source               = "./modules/src/service-plan"
  service_plan_configs = local.service_plan_configs
}
