##Initialize SQL Server PaaS
locals {
  mssql_server_config = {
    for mssql_server_config in var.mssql_server_configs : mssql_server_config.resource_key => mssql_server_config
  }
}

resource "azurerm_mssql_server" "sql_server" {
  for_each = local.mssql_server_config

  name                              = each.value.name
  resource_group_name               = each.value.resource_group_name
  location                          = each.value.location
  version                           = each.value.version
  minimum_tls_version               = each.value.minimum_tls_version
  administrator_login               = each.value.administrator_login
  administrator_login_password      = each.value.administrator_login_password
  connection_policy                 = each.value.connection_policy
  primary_user_assigned_identity_id = each.value.primary_user_assigned_identity_id

  dynamic "azuread_administrator" {
    for_each = try(length(each.value.azuread_administrator), 0) > 0 ? [each.value.azuread_administrator] : []

    content {
      login_username              = lookup(azuread_administrator.value, "login_username", null)
      object_id                   = lookup(azuread_administrator.value, "object_id", null)
      tenant_id                   = lookup(azuread_administrator.value, "tenant_id", null)
      azuread_authentication_only = lookup(azuread_administrator.value, "azuread_authentication_only", null)
    }
  }

  dynamic "identity" {
    for_each = try(length(each.value.identity), 0) > 0 ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = lookup(azuread_administrator.value, "identity_ids", null)
    }
  }

  tags = each.value.tags
}

##Initialize SQL Database PaaS
locals {
  sql_database_list = flatten([
    for key, value in local.mssql_server_config : [
      for db_k, db_v in coalesce(value.databases, []) :
      merge(db_v, {
        mssql_server_key    = "${value.resource_group_name}-${value.name}"
        resource_group_name = value.resource_group_name
        sql_server_name     = value.name
        tags                = value.tags
        diagnostic_settings = value.diagnostic_settings
      })
    ]
  ])
  sql_database_map = {
    for database in local.sql_database_list : "${database.mssql_server_key}-${database.name}" => database
  }
}

resource "azurerm_mssql_database" "sql_database" {
  for_each                    = local.sql_database_map
  name                        = each.value.name
  server_id                   = azurerm_mssql_server.sql_server[each.value.mssql_server_key].id
  max_size_gb                 = each.value.max_size_gb
  sku_name                    = each.value.sku_name
  zone_redundant              = each.value.zone_redundant
  auto_pause_delay_in_minutes = each.value.auto_pause_delay_in_minutes
  collation                   = each.value.collation
  geo_backup_enabled          = each.value.geo_backup_enabled
  license_type                = each.value.license_type
  read_replica_count          = each.value.read_replica_count
  storage_account_type        = each.value.storage_account_type
  min_capacity                = each.value.min_capacity

  dynamic "short_term_retention_policy" {
    for_each = try(length(each.value.short_term_retention_policy), 0) > 0 ? [each.value.short_term_retention_policy] : []

    content {
      retention_days = lookup(short_term_retention_policy.value, "retention_days", null)
    }
  }

  dynamic "long_term_retention_policy" {
    for_each = try(length(each.value.long_term_retention_policy), 0) > 0 ? [each.value.long_term_retention_policy] : []

    content {
      weekly_retention  = lookup(long_term_retention_policy.value, "weekly_retention", null)
      monthly_retention = lookup(long_term_retention_policy.value, "monthly_retention", null)
      yearly_retention  = lookup(long_term_retention_policy.value, "yearly_retention", null)
      week_of_year      = lookup(long_term_retention_policy.value, "week_of_year", null)
    }
  }

  dynamic "threat_detection_policy" {
    for_each = try(length(each.value.threat_detection_policy), 0) > 0 ? [each.value.threat_detection_policy] : []

    content {
      state                      = lookup(threat_detection_policy.value, "state", null)
      disabled_alerts            = lookup(threat_detection_policy.value, "disabled_alerts", null)
      email_account_admins       = lookup(threat_detection_policy.value, "email_account_admins", null)
      email_addresses            = lookup(threat_detection_policy.value, "email_addresses", null)
      retention_days             = lookup(threat_detection_policy.value, "retention_days", null)
      storage_account_access_key = lookup(threat_detection_policy.value, "storage_account_access_key", null)
      storage_endpoint           = lookup(threat_detection_policy.value, "storage_endpoint", null)
    }
  }

  tags = each.value.tags
}

##Initialize SQL Firewall Rules
locals {
  sql_firewall_rule_list = flatten([
    for key, sql_firewall_rule_config in local.mssql_server_config : [
      for k, v in coalesce(sql_firewall_rule_config.firewall_rules, []) :
      merge(v, {
        mssql_server_key    = "${sql_firewall_rule_config.resource_group_name}-${sql_firewall_rule_config.name}"
        resource_group_name = sql_firewall_rule_config.resource_group_name
        sql_server_name     = sql_firewall_rule_config.name
      })
    ]
  ])
  sql_firewall_rule_map = {
    for firewall_rule in local.sql_firewall_rule_list :
    "${firewall_rule.sql_server_name}-${firewall_rule.resource_group_name}-${firewall_rule.name}" => firewall_rule
  }
}

resource "azurerm_mssql_firewall_rule" "sql_firewall_rule" {
  for_each         = local.sql_firewall_rule_map
  name             = each.value.name
  server_id        = azurerm_mssql_server.sql_server[each.value.mssql_server_key].id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

##Initialize SQL Virtual Network IDs
locals {
  sql_virtual_network_rules = flatten([
    for key, value in local.mssql_server_config : [
      for vnet_k, vnet_v in coalesce(value.virtual_network_rules, []) :
      merge(vnet_v, {
        mssql_server_key    = "${value.resource_group_name}-${value.name}"
        resource_group_name = value.resource_group_name
        sql_server_name     = value.name
      })
    ]
  ])
  sql_virtual_network_rules_map = {
    for vnet_rule in local.sql_virtual_network_rules : "${vnet_rule.mssql_server_key}-${vnet_rule.name}" => vnet_rule
  }
}

resource "azurerm_mssql_virtual_network_rule" "sql_vnet_rule" {
  for_each  = local.sql_virtual_network_rules_map
  name      = each.value.name
  server_id = azurerm_mssql_server.sql_server[each.value.mssql_server_key].id
  subnet_id = each.value.subnet_id
}