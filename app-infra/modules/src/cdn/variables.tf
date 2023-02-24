variable "cdn_configs" {
  type = list(object({
    resource_key        = string
    name                = string
    resource_group_name = string
    location            = string
    sku                 = string
    tags                = map(string)
    endpoints = list(object({
      name                      = string
      is_http_allowed           = bool
      is_https_allowed          = bool
      content_types_to_compress = list(string)
      geo_filter = object({
        relative_path = string
        action        = string
        country_codes = list(string)
      })
      is_compression_enabled        = bool
      querystring_caching_behaviour = string
      optimization_type             = string
      origin = object({
        name       = string
        host_name  = string
        http_port  = number
        https_port = number
      })
      origin_host_header = string
      origin_path        = string
      probe_path         = string
      global_delivery_rule = object({
        cache_expiration_action = object({
          behavior = string
          duration = string
        })
        cache_key_query_string_action = object({
          behavior   = string
          parameters = string
        })
        modify_request_header_action = object({
          action = string
          name   = string
          value  = string
        })
        modify_response_header_action = object({
          action = string
          name   = string
          value  = string
        })
        url_redirect_action = object({
          redirect_type = string
          protocol      = string
          hostname      = string
          path          = string
          fragment      = string
          query_string  = string
        })
        url_rewrite_action = object({
          source_pattern          = string
          destination             = string
          preserve_unmatched_path = bool
        })
      })
      delivery_rule = list(object({
        name  = string
        order = number
        cache_expiration_action = object({
          behavior = string
          duration = string
        })
        cache_key_query_string_action = object({
          behavior   = string
          parameters = string
        })
        cookies_condition = object({
          selector         = string
          operator         = string
          negate_condition = bool
          match_values     = list(string)
          transforms       = list(string)
        })
        device_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
        })
        http_version_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
        })
        modify_request_header_action = object({
          action = string
          name   = string
          value  = string
        })
        modify_response_header_action = object({
          action = string
          name   = string
          value  = string
        })
        post_arg_condition = object({
          selector         = string
          operator         = string
          negate_condition = bool
          match_values     = list(string)
          transforms       = list(string)
        })
        query_string_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
          transforms       = list(string)
        })
        remote_address_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
        })
        request_body_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
          transforms       = list(string)
        })
        request_header_condition = object({
          selector         = string
          operator         = string
          negate_condition = bool
          match_values     = list(string)
          transforms       = list(string)
        })
        request_method_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
        })
        request_scheme_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
        })
        request_uri_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
          transforms       = list(string)
        })
        url_file_extension_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
          transforms       = list(string)
        })
        url_file_name_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
          transforms       = list(string)
        })
        url_path_condition = object({
          operator         = string
          negate_condition = bool
          match_values     = list(string)
          transforms       = list(string)
        })
        url_redirect_action = object({
          redirect_type = string
          protocol      = string
          hostname      = string
          path          = string
          fragment      = string
          query_string  = string
        })
        url_rewrite_action = object({
          source_pattern          = string
          destination             = string
          preserve_unmatched_path = bool
        })
      }))
      custom_domain = object({
        name      = string
        host_name = string
        cdn_managed_https = object({
          certificate_type = string
          protocol_type    = string
          tls_version      = string
        })
        user_managed_https = object({
          key_vault_secret_id = string
          tls_version         = string
        })
      })
      tags = map(string)
    }))
    role_assignments = list(
      object(
        {
          role_definition_id = string
          object_ids         = list(string)
        }
      )
    )
  }))
}