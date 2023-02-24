variable "cdn_configs" {
  type = object({
    resource_group_name = string
    role_assignments = optional(list(object(
      {
        role_definition_id = string
        object_ids         = list(string)
      }
      )
    ), [])
    tags = optional(map(string), {})
    cdn = list(object({
      name                = string
      resource_group_name = optional(string)
      sku                 = string
      tags                = optional(map(string), {})
      endpoints = optional(list(object({
        name                      = string
        is_http_allowed           = optional(bool)
        is_https_allowed          = optional(bool)
        content_types_to_compress = optional(list(string), [])
        geo_filter = optional(object({
          relative_path = string
          action        = string
          country_codes = list(string)
        }))
        is_compression_enabled        = optional(bool)
        querystring_caching_behaviour = optional(string)
        optimization_type             = optional(string)
        origin = object({
          name       = string
          host_name  = string
          http_port  = optional(number)
          https_port = optional(number)
        })
        origin_host_header = optional(string)
        origin_path        = optional(string)
        probe_path         = optional(string)
        global_delivery_rule = optional(object({
          cache_expiration_action = optional(object({
            behavior = string
            duration = optional(string)
          }))
          cache_key_query_string_action = optional(object({
            behavior   = string
            parameters = optional(string)
          }))
          modify_request_header_action = optional(object({
            action = string
            name   = string
            value  = optional(string)
          }))
          modify_response_header_action = optional(object({
            action = string
            name   = string
            value  = optional(string)
          }))
          url_redirect_action = optional(object({
            redirect_type = string
            protocol      = optional(string)
            hostname      = optional(string)
            path          = optional(string)
            fragment      = optional(string)
            query_string  = optional(string)
          }))
          url_rewrite_action = optional(object({
            source_pattern          = string
            destination             = string
            preserve_unmatched_path = optional(bool)
          }))
        }))
        delivery_rule = optional(list(object({
          name  = string
          order = number
          cache_expiration_action = optional(object({
            behavior = string
            duration = optional(string)
          }))
          cache_key_query_string_action = optional(object({
            behavior   = string
            parameters = optional(string)
          }))
          cookies_condition = optional(object({
            selector         = string
            operator         = string
            negate_condition = optional(bool)
            match_values     = optional(list(string))
            transforms       = optional(list(string))
          }))
          device_condition = optional(object({
            operator         = optional(string)
            negate_condition = optional(bool)
            match_values     = list(string)
          }))
          http_version_condition = object({
            operator         = optional(string)
            negate_condition = optional(bool)
            match_values     = list(string)
          })
          modify_request_header_action = optional(object({
            action = string
            name   = string
            value  = optional(string)
          }))
          modify_response_header_action = optional(object({
            action = string
            name   = string
            value  = optional(string)
          }))
          post_arg_condition = optional(object({
            selector         = string
            operator         = string
            negate_condition = optional(bool)
            match_values     = optional(list(string))
            transforms       = optional(list(string))
          }))
          query_string_condition = object({
            operator         = string
            negate_condition = optional(bool)
            match_values     = optional(list(string))
            transforms       = optional(list(string))
          })
          remote_address_condition = optional(object({
            operator         = string
            negate_condition = optional(bool)
            match_values     = optional(list(string))
          }))
          request_body_condition = optional(object({
            operator         = string
            negate_condition = optional(bool)
            match_values     = optional(list(string))
            transforms       = optional(list(string))
          }))
          request_header_condition = optional(object({
            selector         = string
            operator         = string
            negate_condition = optional(bool)
            match_values     = optional(list(string))
            transforms       = optional(list(string))
          }))
          request_method_condition = optional(object({
            operator         = optional(string)
            negate_condition = optional(bool)
            match_values     = list(string)
          }))
          request_scheme_condition = optional(object({
            operator         = optional(string)
            negate_condition = optional(bool)
            match_values     = list(string)
          }))
          request_uri_condition = optional(object({
            operator         = string
            negate_condition = optional(bool)
            match_values     = optional(list(string))
            transforms       = optional(list(string))
          }))
          url_file_extension_condition = optional(object({
            operator         = string
            negate_condition = optional(bool)
            match_values     = optional(list(string))
            transforms       = optional(list(string))
          }))
          url_file_name_condition = optional(object({
            operator         = string
            negate_condition = optional(bool)
            match_values     = optional(list(string))
            transforms       = optional(list(string))
          }))
          url_path_condition = optional(object({
            operator         = string
            negate_condition = optional(bool)
            match_values     = optional(list(string))
            transforms       = optional(list(string))
          }))
          url_redirect_action = optional(object({
            redirect_type = string
            protocol      = optional(string)
            hostname      = optional(string)
            path          = optional(string)
            fragment      = optional(string)
            query_string  = optional(string)
          }))
          url_rewrite_action = optional(object({
            source_pattern          = string
            destination             = string
            preserve_unmatched_path = optional(bool)
          }))
        })), [])
        custom_domain = optional(object({
          name      = string
          host_name = string
          cdn_managed_https = optional(object({
            certificate_type = string
            protocol_type    = string
          }))
          user_managed_https = optional(object({
            key_vault_secret_id = string
          }))
        }))
        tags = optional(map(string), {})
      })), [])
    }))
  })

  default = null

}

locals {
  cdn_inputs           = var.cdn_configs
  cdn_rgp              = try(local.cdn_inputs.resource_group_name, null)
  cdn_role_assignments = try(local.cdn_inputs.role_assignments, [])
  cdn_tags             = try(local.cdn_inputs.tags, {})
  cdn_list             = try(local.cdn_inputs.cdn, [])

  cdn_resource_groups = distinct([
    for cdn in local.cdn_list : {
      name             = coalesce(cdn.resource_group_name, local.cdn_rgp)
      resource_key     = lower(coalesce(cdn.resource_group_name, local.cdn_rgp))
      role_assignments = local.role_assignments
      location         = local.location
      tags             = local.common_resource_tags
    }
  ])

  cdn_configs_map = {
    for cdn in local.cdn_list : cdn.name => {
      resource_key = lower(format(
        "%s/%s",
        coalesce(cdn.resource_group_name, local.cdn_rgp),
        cdn.name
      ))
      resource_group_name = module.resource_groups.outputs[lower(coalesce(cdn.resource_group_name, local.cdn_rgp))].name
      location            = local.location
      tags = merge(
        local.cdn_tags,
        cdn.tags,
        local.common_resource_tags
      )
      role_assignments = local.cdn_role_assignments
      name             = cdn.name
      sku              = cdn.sku
      endpoints = [
        for endpoint in cdn.endpoints : {
          name                          = endpoint.name
          is_http_allowed               = endpoint.is_http_allowed
          is_https_allowed              = endpoint.is_https_allowed
          content_types_to_compress     = endpoint.content_types_to_compress
          geo_filter                    = endpoint.geo_filter
          is_compression_enabled        = endpoint.is_compression_enabled
          querystring_caching_behaviour = endpoint.querystring_caching_behaviour
          optimization_type             = endpoint.optimization_type
          origin                        = endpoint.origin
          origin_host_header            = endpoint.origin_host_header
          origin_path                   = endpoint.origin_path
          probe_path                    = endpoint.probe_path
          global_delivery_rule          = endpoint.global_delivery_rule
          delivery_rule                 = endpoint.delivery_rule
          tags = merge(
            local.cdn_tags,
            cdn.tags,
            endpoint.tags,
            local.common_resource_tags
          )
          custom_domain = endpoint.custom_domain != null ? {
            name      = endpoint.custom_domain.name
            host_name = endpoint.custom_domain.host_name
            cdn_managed_https = endpoint.custom_domain.cdn_managed_https != null ? {
              certificate_type = endpoint.custom_domain.cdn_managed_https.certificate_type
              protocol_type    = endpoint.custom_domain.cdn_managed_https.protocol_type
              tls_version      = "TLS12"
            } : null
            user_managed_https = endpoint.custom_domain.user_managed_https != null ? {
              key_vault_secret_id = endpoint.custom_domain.user_managed_https.key_vault_secret_id
              tls_version         = "TLS12"
            } : null
          } : null
        }
      ]
    }
  }

  cdn_configs = values(local.cdn_configs_map)
}

module "cdn" {
  source      = "./modules/src/cdn"
  cdn_configs = local.cdn_configs
}
