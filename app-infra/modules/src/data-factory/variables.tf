variable "data_factory_configs" {
  type = list(object({
    resource_key                     = string
    name                             = string
    location                         = string
    resource_group_name              = string
    managed_virtual_network_enabled  = bool
    public_network_enabled           = bool
    customer_managed_key_id          = string
    customer_managed_key_identity_id = string
    github_configuration = object({
      account_name    = string
      branch_name     = string
      git_url         = string
      repository_name = string
      root_folder     = string
    })
    global_parameter = list(object({
      name  = string
      type  = string
      value = string
    }))
    identity = object(
      {
        type                = string
        user_identity_names = list(string)
      }
    )
    vsts_configuration = object({
      account_name    = string
      branch_name     = string
      project_name    = string
      repository_name = string
      root_folder     = string
      tenant_id       = string
    })
    # #initialize azurerm_data_factory_integration_runtime_azure
    # data_factory_integration_runtime = object({
    #   name                    = string
    #   description             = string
    #   cleanup_enabled         = bool
    #   compute_type            = string
    #   core_count              = number
    #   time_to_live_min        = number
    #   virtual_network_enabled = bool
    # })
    # #initialize azurerm_data_factory_integration_runtime_self_hosted
    # data_factory_integration_runtime_self_hosted = object({
    #   name        = string
    #   description = string
    #   rbac_authorization = object({
    #     resource_id = string
    #   })
    # })
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
  }))
}

variable "app_key_vault_id" {
  type    = string
  default = null
}