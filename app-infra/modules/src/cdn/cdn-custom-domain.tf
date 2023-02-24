locals {
  cdn_custom_domains = {
    for endpoint_key, endpoint in local.cdn_endpoints : lower(format("%s/%s", endpoint_key, endpoint.custom_domain.name)) => merge(endpoint.custom_domain, {
      endpoint_key = endpoint_key
    }) if endpoint.custom_domain != null
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "cdn_endpoint_custom_domain" {
  for_each        = local.cdn_custom_domains
  name            = each.value.name
  cdn_endpoint_id = azurerm_cdn_endpoint.cdn_endpoint[each.value.endpoint_key].id
  host_name       = each.value.host_name

  dynamic "cdn_managed_https" {
    for_each = try(length(each.value.cdn_managed_https) > 0, false) ? [each.value.cdn_managed_https] : []

    content {
      certificate_type = cdn_managed_https.value.certificate_type
      protocol_type    = cdn_managed_https.value.protocol_type
      tls_version      = cdn_managed_https.value.tls_version
    }
  }

  dynamic "user_managed_https" {
    for_each = try(length(each.value.user_managed_https) > 0, false) ? [each.value.user_managed_https] : []

    content {
      key_vault_secret_id = user_managed_https.value.key_vault_secret_id
      tls_version         = user_managed_https.value.tls_version
    }
  }
}