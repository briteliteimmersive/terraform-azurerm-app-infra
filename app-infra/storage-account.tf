variable "storage_acc_configs" {
  type = object({
    resource_group_name = string
    network_rules = optional(object({
      public_ip_ranges = list(string)
      subnet_ids       = list(string)
      }), {
      public_ip_ranges = []
      subnet_ids       = []
    })
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
    storage_accounts = list(object(
      {
        name                              = string
        resource_group_name               = optional(string)
        account_tier                      = optional(string, "Standard")
        account_replication_type          = optional(string, "LRS")
        account_kind                      = optional(string, "StorageV2")
        access_tier                       = optional(string, "Hot")
        cross_tenant_replication_enabled  = optional(bool)
        edge_zone                         = optional(string)
        is_hns_enabled                    = optional(bool, false)
        large_file_share_enabled          = optional(bool)
        infrastructure_encryption_enabled = optional(bool, true)
        tags                              = optional(map(string), {})
        blob_properties = optional(object(
          {
            versioning_enabled  = bool
            change_feed_enabled = bool
            container_delete_retention_policy = object(
              {
                days = number
              }
            )
            delete_retention_policy = object(
              {
                days = number
              }
            )
          }
        ))
        containers = optional(list(object({
          name                  = string
          container_access_type = optional(string, "private")
          metadata              = optional(map(string), {})
        })), [])
        file_shares = optional(list(
          object(
            {
              name  = string
              quota = number
            }
          )
        ), [])

      }
    ))
  })

  default = null
}

locals {

  storage_acc_inputs              = var.storage_acc_configs
  storage_acc_rgp                 = try(local.storage_acc_inputs.resource_group_name, null)
  storage_acc_network_rules       = try(local.storage_acc_inputs.network_rules, null)
  storage_acc_diagnostic_settings = try(local.storage_acc_inputs.diagnostic_settings, null)
  storage_acc_role_assignments    = try(local.storage_acc_inputs.role_assignments, [])
  storage_acc_tags                = try(local.storage_acc_inputs.tags, {})
  storage_acc_list                = try(local.storage_acc_inputs.storage_accounts, [])

  storage_resource_groups = distinct([
    for storage in local.storage_acc_list : {
      name             = coalesce(storage.resource_group_name, local.storage_acc_rgp)
      resource_key     = lower(coalesce(storage.resource_group_name, local.storage_acc_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])


  storage_acc_configs_map = {
    for storage in local.storage_acc_list : storage.name => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(storage.resource_group_name, local.storage_acc_rgp),
        storage.name
      ))
      resource_group_name       = module.resource_groups.outputs[lower(coalesce(storage.resource_group_name, local.storage_acc_rgp))].name
      location                  = local.location
      enable_https_traffic_only = true
      ## Needed by terraform
      shared_access_key_enabled       = true
      allow_nested_items_to_be_public = false
      min_tls_version                 = "TLS1_2"
      tags = merge(
        local.storage_acc_tags,
        storage.tags,
        local.common_resource_tags
      )
      network_rules = {
        default_action = length(local.deployment_agent_subnet_id) > 0 ? "Deny" : "Allow"
        bypass         = ["Logging", "Metrics", "AzureServices"]
        ip_rules = distinct(concat(
          [for ip_range in local.network_rules.public_ip_ranges : replace(replace(ip_range, "/32", ""), "/31", "")],
          [for ip_range in local.storage_acc_network_rules.public_ip_ranges : replace(replace(ip_range, "/32", ""), "/31", "")]
        ))
        virtual_network_subnet_ids = distinct(concat(
          local.deployment_agent_subnet_id,
          local.network_rules.subnet_ids,
          local.storage_acc_network_rules.subnet_ids,
          [for name, id in local.subnet_ids_by_name : id]
        ))
      }
      diagnostic_settings = try(length(local.storage_acc_diagnostic_settings) > 0, false) ? [
        for setting in local.storage_acc_diagnostic_settings.settings : {
          name   = setting.name
          log    = setting.log
          metric = setting.metric
          log_analytics_workspace_name = try(
            local.storage_acc_diagnostic_settings.log_analytics_workspace_name,
            null
          )
          log_analytics_workspace_id = try(
            local.storage_acc_diagnostic_settings.log_analytics_workspace_id,
            # module.log_analytics.outputs[local.storage_acc_diagnostic_settings.log_analytics_workspace_name].id, ## Needs fixing
            null
          )
        }
      ] : []
      role_assignments = local.storage_acc_role_assignments
      name             = storage.name
      account_kind     = storage.account_kind
      blob_properties  = storage.blob_properties
      ## For BlockBlobStorage and FileStorage accounts only Premium is valid.
      account_tier             = contains(["blockblobstorage", "filestorage"], lower(try(storage.account_kind, "StorageV2"))) ? "Premium" : storage.account_tier
      account_replication_type = storage.account_replication_type
      ## For BlobStorage, FileStorage and StorageV2 accounts only
      access_tier = contains(["blobstorage", "filestorage", "storagev2"], lower(try(storage.account_kind, "StorageV2"))) ? storage.access_tier : null
      edge_zone   = storage.edge_zone
      ## This can only be true when account_tier is Standard or when account_tier is Premium and account_kind is BlockBlobStorage
      is_hns_enabled = (
        lower(try(storage.account_tier, "Standard")) == "standard" ||
        (lower(try(storage.account_tier, "Standard")) == "premium" && lower(try(storage.account_kind, "StorageV2")) == "blockblobstorage")
      ) ? storage.is_hns_enabled : false
      ## This cannot be true when account_replication_type = GRS/RAGRS/RAGZRS/GZRS
      large_file_share_enabled = contains(["GRS", "RAGRS", "RAGZRS", "GZRS"], try(storage.account_replication_type, "LRS")) ? null : try(storage.large_file_share_enabled, true)
      ## This can only be true when account_kind is StorageV2 or when account_tier is Premium and account_kind is BlockBlobStorage.
      infrastructure_encryption_enabled = (
        lower(try(storage.account_tier, "Standard")) == "standard" ||
        (lower(try(storage.account_tier, "Standard")) == "premium" && lower(try(storage.account_kind, "StorageV2")) == "blockblobstorage")
      ) ? storage.infrastructure_encryption_enabled : false
      cross_tenant_replication_enabled = storage.cross_tenant_replication_enabled
      containers = try(length(storage.containers), 0) > 0 ? [
        for container in storage.containers : {
          name                  = container.name
          container_access_type = try(container.container_access_type, "private")
          metadata              = try(container.metadata, {})
        }
      ] : []
      file_shares = try(length(storage.file_shares), 0) > 0 ? [
        for file_share in storage.file_shares : {
          name  = file_share.name
          quota = file_share.quota
        }
      ] : []
    }
  }

  storage_acc_configs = values(local.storage_acc_configs_map)

}

module "storage_accounts" {
  source              = "./modules/src/storage-account"
  storage_acc_configs = local.storage_acc_configs
  app_key_vault_id    = local.infra_keyvault_id
}

output "storage_accounts" {
  value = module.storage_accounts.outputs
}