locals {
  cdn_endpoints_list = flatten([
    for cdn_key, cdn_config in local.cdn_configs : [
      for endpoint in cdn_config.endpoints : merge(endpoint, {
        cdn_endpoint_key = lower(format("%s/%s", cdn_key, endpoint.name))
        cdn_key          = cdn_key
      })
    ]
  ])

  cdn_endpoints = {
    for cdn_endpoint in local.cdn_endpoints_list : cdn_endpoint.cdn_endpoint_key => cdn_endpoint
  }
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  for_each                      = local.cdn_endpoints
  name                          = each.value.name
  profile_name                  = azurerm_cdn_profile.cdn_profile[each.value.cdn_key].name
  location                      = azurerm_cdn_profile.cdn_profile[each.value.cdn_key].location
  resource_group_name           = azurerm_cdn_profile.cdn_profile[each.value.cdn_key].resource_group_name
  is_http_allowed               = each.value.is_http_allowed
  is_https_allowed              = each.value.is_https_allowed
  content_types_to_compress     = each.value.content_types_to_compress
  is_compression_enabled        = each.value.is_compression_enabled
  querystring_caching_behaviour = each.value.querystring_caching_behaviour
  optimization_type             = each.value.optimization_type
  origin_host_header            = each.value.origin_host_header
  origin_path                   = each.value.origin_path
  probe_path                    = each.value.probe_path
  tags                          = each.value.tags

  origin {
    name       = each.value.origin.name
    host_name  = each.value.origin.host_name
    http_port  = each.value.origin.http_port
    https_port = each.value.origin.https_port
  }

  dynamic "geo_filter" {
    for_each = try(length(each.value.geo_filter) > 0, false) ? [each.value.geo_filter] : []

    content {
      relative_path = geo_filter.value.relative_path
      action        = geo_filter.value.action
      country_codes = geo_filter.value.country_codes
    }
  }

  dynamic "global_delivery_rule" {
    for_each = try(length(each.value.global_delivery_rule) > 0, false) ? [each.value.global_delivery_rule] : []

    content {

      dynamic "cache_expiration_action" {
        for_each = try(length(global_delivery_rule.value.cache_expiration_action) > 0, false) ? [global_delivery_rule.value.cache_expiration_action] : []
        content {
          behavior = cache_expiration_action.value.behavior
          duration = cache_expiration_action.value.duration
        }
      }

      dynamic "cache_key_query_string_action" {
        for_each = try(length(global_delivery_rule.value.cache_key_query_string_action) > 0, false) ? [global_delivery_rule.value.cache_key_query_string_action] : []
        content {
          behavior   = cache_key_query_string_action.value.behavior
          parameters = cache_key_query_string_action.value.parameters
        }
      }

      dynamic "modify_request_header_action" {
        for_each = try(length(global_delivery_rule.value.modify_request_header_action) > 0, false) ? [global_delivery_rule.value.modify_request_header_action] : []
        content {
          action = modify_request_header_action.value.action
          name   = modify_request_header_action.value.name
          value  = modify_request_header_action.value.value
        }
      }

      dynamic "modify_response_header_action" {
        for_each = try(length(global_delivery_rule.value.modify_response_header_action) > 0, false) ? [global_delivery_rule.value.modify_response_header_action] : []
        content {
          action = modify_response_header_action.value.action
          name   = modify_response_header_action.value.name
          value  = modify_response_header_action.value.value
        }
      }

      dynamic "url_redirect_action" {
        for_each = try(length(global_delivery_rule.value.url_redirect_action) > 0, false) ? [global_delivery_rule.value.url_redirect_action] : []
        content {
          redirect_type = url_redirect_action.value.redirect_type
          protocol      = url_redirect_action.value.protocol
          hostname      = url_redirect_action.value.hostname
          path          = url_redirect_action.value.path
          fragment      = url_redirect_action.value.fragment
          query_string  = url_redirect_action.value.query_string
        }
      }

      dynamic "url_rewrite_action" {
        for_each = try(length(global_delivery_rule.value.url_rewrite_action) > 0, false) ? [global_delivery_rule.value.url_rewrite_action] : []
        content {
          source_pattern          = url_rewrite_action.value.source_pattern
          destination             = url_rewrite_action.value.destination
          preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
        }
      }
    }
  }

  dynamic "delivery_rule" {
    for_each = try(length(each.value.delivery_rule) > 0, false) ? each.value.delivery_rule : []

    content {

      name  = delivery_rule.value.name
      order = delivery_rule.value.order

      dynamic "cache_expiration_action" {
        for_each = try(length(delivery_rule.value.cache_expiration_action) > 0, false) ? [delivery_rule.value.cache_expiration_action] : []
        content {
          behavior = cache_expiration_action.value.behavior
          duration = cache_expiration_action.value.duration
        }
      }

      dynamic "cache_key_query_string_action" {
        for_each = try(length(delivery_rule.value.cache_key_query_string_action) > 0, false) ? [delivery_rule.value.cache_key_query_string_action] : []
        content {
          behavior   = cache_key_query_string_action.value.behavior
          parameters = cache_key_query_string_action.value.parameters
        }
      }

      dynamic "cookies_condition" {
        for_each = try(length(delivery_rule.value.cookies_condition) > 0, false) ? [delivery_rule.value.cookies_condition] : []
        content {
          selector         = cookies_condition.value.selector
          operator         = cookies_condition.value.operator
          negate_condition = cookies_condition.value.negate_condition
          match_values     = cookies_condition.value.match_values
          transforms       = cookies_condition.value.transforms
        }
      }

      dynamic "device_condition" {
        for_each = try(length(delivery_rule.value.device_condition) > 0, false) ? [delivery_rule.value.device_condition] : []
        content {
          operator         = device_condition.value.operator
          negate_condition = device_condition.value.negate_condition
          match_values     = device_condition.value.match_values
        }
      }

      dynamic "http_version_condition" {
        for_each = try(length(delivery_rule.value.http_version_condition) > 0, false) ? [delivery_rule.value.http_version_condition] : []
        content {
          operator         = http_version_condition.value.operator
          negate_condition = http_version_condition.value.negate_condition
          match_values     = http_version_condition.value.match_values
        }
      }

      dynamic "modify_request_header_action" {
        for_each = try(length(delivery_rule.value.modify_request_header_action) > 0, false) ? [delivery_rule.value.modify_request_header_action] : []
        content {
          action = modify_request_header_action.value.action
          name   = modify_request_header_action.value.name
          value  = modify_request_header_action.value.value
        }
      }

      dynamic "modify_response_header_action" {
        for_each = try(length(delivery_rule.value.modify_response_header_action) > 0, false) ? [delivery_rule.value.modify_response_header_action] : []
        content {
          action = modify_response_header_action.value.action
          name   = modify_response_header_action.value.name
          value  = modify_response_header_action.value.value
        }
      }

      dynamic "post_arg_condition" {
        for_each = try(length(delivery_rule.value.post_arg_condition) > 0, false) ? [delivery_rule.value.post_arg_condition] : []
        content {
          selector         = post_arg_condition.value.selector
          operator         = post_arg_condition.value.operator
          negate_condition = post_arg_condition.value.negate_condition
          match_values     = post_arg_condition.value.match_values
          transforms       = post_arg_condition.value.transforms
        }
      }

      dynamic "query_string_condition" {
        for_each = try(length(delivery_rule.value.query_string_condition) > 0, false) ? [delivery_rule.value.query_string_condition] : []
        content {
          operator         = query_string_condition.value.operator
          negate_condition = query_string_condition.value.negate_condition
          match_values     = query_string_condition.value.match_values
          transforms       = query_string_condition.value.transforms
        }
      }

      dynamic "remote_address_condition" {
        for_each = try(length(delivery_rule.value.remote_address_condition) > 0, false) ? [delivery_rule.value.remote_address_condition] : []
        content {
          operator         = remote_address_condition.value.operator
          negate_condition = remote_address_condition.value.negate_condition
          match_values     = remote_address_condition.value.match_values
        }
      }

      dynamic "request_body_condition" {
        for_each = try(length(delivery_rule.value.request_body_condition) > 0, false) ? [delivery_rule.value.request_body_condition] : []
        content {
          operator         = request_body_condition.value.operator
          negate_condition = request_body_condition.value.negate_condition
          match_values     = request_body_condition.value.match_values
          transforms       = request_body_condition.value.transforms
        }
      }

      dynamic "request_header_condition" {
        for_each = try(length(delivery_rule.value.request_header_condition) > 0, false) ? [delivery_rule.value.request_header_condition] : []
        content {
          selector         = request_header_condition.value.selector
          operator         = request_header_condition.value.operator
          negate_condition = request_header_condition.value.negate_condition
          match_values     = request_header_condition.value.match_values
          transforms       = request_header_condition.value.transforms
        }
      }

      dynamic "request_method_condition" {
        for_each = try(length(delivery_rule.value.request_method_condition) > 0, false) ? [delivery_rule.value.request_method_condition] : []
        content {
          operator         = request_method_condition.value.operator
          negate_condition = request_method_condition.value.negate_condition
          match_values     = request_method_condition.value.match_values
        }
      }

      dynamic "request_scheme_condition" {
        for_each = try(length(delivery_rule.value.request_scheme_condition) > 0, false) ? [delivery_rule.value.request_scheme_condition] : []
        content {
          operator         = request_scheme_condition.value.operator
          negate_condition = request_scheme_condition.value.negate_condition
          match_values     = request_scheme_condition.value.match_values
        }
      }

      dynamic "request_uri_condition" {
        for_each = try(length(delivery_rule.value.request_uri_condition) > 0, false) ? [delivery_rule.value.request_uri_condition] : []
        content {
          operator         = request_uri_condition.value.operator
          negate_condition = request_uri_condition.value.negate_condition
          match_values     = request_uri_condition.value.match_values
          transforms       = request_uri_condition.value.transforms
        }
      }

      dynamic "url_file_extension_condition" {
        for_each = try(length(delivery_rule.value.url_file_extension_condition) > 0, false) ? [delivery_rule.value.url_file_extension_condition] : []
        content {
          operator         = url_file_extension_condition.value.operator
          negate_condition = url_file_extension_condition.value.negate_condition
          match_values     = url_file_extension_condition.value.match_values
          transforms       = url_file_extension_condition.value.transforms
        }
      }

      dynamic "url_file_name_condition" {
        for_each = try(length(delivery_rule.value.url_file_name_condition) > 0, false) ? [delivery_rule.value.url_file_name_condition] : []
        content {
          operator         = url_file_name_condition.value.operator
          negate_condition = url_file_name_condition.value.negate_condition
          match_values     = url_file_name_condition.value.match_values
          transforms       = url_file_name_condition.value.transforms
        }
      }

      dynamic "url_path_condition" {
        for_each = try(length(delivery_rule.value.url_path_condition) > 0, false) ? [delivery_rule.value.url_path_condition] : []
        content {
          operator         = url_path_condition.value.operator
          negate_condition = url_path_condition.value.negate_condition
          match_values     = url_path_condition.value.match_values
          transforms       = url_path_condition.value.transforms
        }
      }

      dynamic "url_redirect_action" {
        for_each = try(length(delivery_rule.value.url_redirect_action) > 0, false) ? [delivery_rule.value.url_redirect_action] : []
        content {
          redirect_type = url_redirect_action.value.redirect_type
          protocol      = url_redirect_action.value.protocol
          hostname      = url_redirect_action.value.hostname
          path          = url_redirect_action.value.path
          fragment      = url_redirect_action.value.fragment
          query_string  = url_redirect_action.value.query_string
        }
      }

      dynamic "url_rewrite_action" {
        for_each = try(length(delivery_rule.value.url_rewrite_action) > 0, false) ? [delivery_rule.value.url_rewrite_action] : []
        content {
          source_pattern          = url_rewrite_action.value.source_pattern
          destination             = url_rewrite_action.value.destination
          preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
        }
      }
    }
  }

}