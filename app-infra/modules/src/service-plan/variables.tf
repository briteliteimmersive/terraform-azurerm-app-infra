variable "service_plan_configs" {
  type = list(
    object(
      {
        resource_key                 = string
        name                         = string
        resource_group_name          = string
        location                     = string
        os_type                      = string
        sku_name                     = string
        app_service_environment_id   = string
        per_site_scaling_enabled     = bool
        worker_count                 = number
        zone_balancing_enabled       = bool
        maximum_elastic_worker_count = number
        # diagnostic_settings = list(object(
        #   {
        #     name                         = string
        #     log_analytics_workspace_name = string
        #     log_analytics_workspace_id   = string
        #     log = list(object(
        #       {
        #         category       = string
        #         category_group = string
        #         enabled        = bool
        #         retention_policy = object(
        #           {
        #             enabled = bool
        #             days    = number
        #           }
        #         )
        #       }
        #     ))
        #     metric = list(object(
        #       {
        #         category = string
        #         enabled  = bool
        #         retention_policy = object(
        #           {
        #             enabled = bool
        #             days    = number
        #           }
        #         )
        #       }
        #     ))
        #   }
        # ))
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
  )
}