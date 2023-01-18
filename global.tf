variable "global_configs" {
  type = object(
    {
      location = optional(string, "westus")
      mandatory_tags = object(
        {
          app-id        = string
          solution      = string
          businessunit  = string
          costcenter    = string
          srid          = string
          businessowner = string
          support-queue = string
          criticality   = string
          environment   = string
        }
      )
      app_network = optional(object(
        {
          vnet_name                = string
          vnet_resource_group_name = string
          subnets                  = list(string)
        }
      ))
      deployment_agent = optional(object(
        {
          subscription_id          = string
          vnet_name                = string
          vnet_resource_group_name = string
          subnet_name              = string
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
      central_log_analytics_workspace = optional(object(
        {
          subscription_id     = string
          name                = string
          resource_group_name = string
        }
      ))
      network_rules = optional(object({
        public_ip_ranges = list(string)
        subnet_ids       = list(string)
        }), {
        public_ip_ranges = []
        subnet_ids       = []
      })
    }
  )

  validation {
    condition     = length(var.global_configs.mandatory_tags.app-id) == 4
    error_message = "The 'app-id' tag value must be exactly 4 characters long."
  }
}

variable "deployment_info" {
  type    = string
  default = "{“version”: “”, “commit-id”: “”, “pipeline-name”:””, “github-repo”: “”}"
}

## Run-time data inputs
data "azurerm_subscription" "current_sub" {
}

data "azurerm_client_config" "current_client" {
}

locals {

  global_configs  = var.global_configs
  app_unique_code = local.global_configs.mandatory_tags.app-id
  environment     = local.global_configs.mandatory_tags.environment
  location        = local.global_configs.location
  network_rules   = local.global_configs.network_rules

  common_resource_tags = merge(
    local.global_configs.mandatory_tags, {
      deployed-by = var.deployment_info
    }
  )

  subscription_id   = data.azurerm_subscription.current_sub.subscription_id
  subscription_name = data.azurerm_subscription.current_sub.display_name
  client_object_id  = data.azurerm_client_config.current_client.object_id
  client_tenant_id  = data.azurerm_client_config.current_client.tenant_id

  deployment_agent_subnet_id = try([format("/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/virtualNetworks/%s/subnets/%s",
    local.global_configs.deployment_agent.subscription_id,
    local.global_configs.deployment_agent.vnet_resource_group_name,
    local.global_configs.deployment_agent.vnet_name,
    local.global_configs.deployment_agent.subnet_name
  )], [])

  app_network = local.global_configs.app_network

  role_assignments = try(length(local.global_configs.role_assignments) > 0, false) ? local.global_configs.role_assignments : []

}