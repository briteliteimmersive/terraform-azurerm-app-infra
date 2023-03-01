variable "data_factory_configs" {
  type = list(object({
    resource_key                            = string
    name                                    = string
    location                                = string
    resource_group_name                     = string
    managed_virtual_network_enabled         = bool
    public_network_enabled                  = bool
    customer_managed_key_user_identity_name = string
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
    keyvault_linked_services = list(object({
      name                     = string
      key_vault_name           = string
      key_vault_id             = string
      description              = string
      integration_runtime_name = string
      annotations              = list(string)
      parameters               = map(string)
      additional_properties    = map(string)
    }))
    adls_gen2_linked_services = list(object({
      name                     = string
      url                      = string
      storage_account_name     = string
      storage_account_id       = string
      description              = string
      integration_runtime_name = string
      annotations              = list(string)
      parameters               = map(string)
      additional_properties    = map(string)
    }))
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

variable "admin_key_vault_id" {
  type = string
}