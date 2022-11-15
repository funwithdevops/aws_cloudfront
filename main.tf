locals {
  ttl_policies = {
    "none" = {
      default = 0
      max     = 0
    }
    "short" = {
      default = 30
      max     = 300
    }
    "long" = {
      default = 300
      max     = 86400
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = var.custom_domain_name
  aliases             = [var.custom_domain_name]
  default_root_object = var.default_root_object
  price_class         = "PriceClass_100" # This will cache the content only North America and Europe
  http_version        = "http1.1"

  # !!! TODO
  # web_acl_id = data.aws_waf_web_acl.FM_Managed.id

  lifecycle {
    ignore_changes = [web_acl_id]
  }

  default_cache_behavior {
    allowed_methods  = coalesce(var.default_cache_behavior.allowed_methods, ["GET", "HEAD"])
    cached_methods   = coalesce(var.default_cache_behavior.cached_methods, ["GET", "HEAD"])
    target_origin_id = var.default_cache_behavior.origin_id
    min_ttl          = 0
    default_ttl      = lookup(local.ttl_policies, var.default_cache_behavior.ttl_policy)["default"]
    max_ttl          = lookup(local.ttl_policies, var.default_cache_behavior.ttl_policy)["max"]

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = coalesce(var.default_cache_behavior.forwarded_query_string, true)
      headers      = coalesce(var.default_cache_behavior.forwarded_headers, [])

      cookies {
        forward = coalesce(var.default_cache_behavior.forwarded_cookies, "none")
      }
    }

    dynamic "lambda_function_association" {
      for_each = var.default_cache_behavior.lambda_function_associations
      iterator = lambda

      content {
        event_type = lambda.value.event_type
        lambda_arn = lambda.value.lambda_arn
      }
    }
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
    acm_certificate_arn      = var.viewer_certificate_arn
  }

  dynamic "origin" {
    for_each = var.origins
    content {
      origin_id   = origin.value.origin_id
      domain_name = origin.value.domain_name
      
      dynamic "s3_origin_config" {
        for_each = origin.value.s3_origin_config == null ? [] : [origin.value.s3_origin_config] # s3_origin hack to make it dynamic
        iterator = conf
        content {
          origin_access_identity = lookup(conf.value, "origin_access_identity", null)
        }
      }

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config == null ? [] : [origin.value.custom_origin_config]
        iterator = config
        content {
          http_port                = lookup(config.value, "http_port", 80)
          https_port               = lookup(config.value, "https_port", 443)
          origin_protocol_policy   = lookup(config.value, "origin_protocol_policy", "https-only")
          origin_ssl_protocols     = lookup(config.value, "origin_ssl_protocols", ["TLSv1.2"])
          origin_keepalive_timeout = lookup(config.value, "origin_keepalive_timeout", null)
          origin_read_timeout      = lookup(config.value, "origin_read_timeout", null)
        }
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    iterator = cache
    content {
      allowed_methods  = coalesce(cache.value.allowed_methods, ["GET", "HEAD"])
      cached_methods   = coalesce(cache.value.cached_methods, ["GET", "HEAD"])
      target_origin_id = cache.value.origin_id
      path_pattern     = cache.value.path_pattern
      min_ttl          = 0
      default_ttl      = lookup(local.ttl_policies, cache.value.ttl_policy)["default"]
      max_ttl          = lookup(local.ttl_policies, cache.value.ttl_policy)["max"]

      viewer_protocol_policy = "redirect-to-https"

      forwarded_values {
        query_string = coalesce(cache.value.forwarded_query_string, true)
        headers      = coalesce(cache.value.forwarded_headers, [])

        cookies {
          forward = coalesce(cache.value.forwarded_cookies, "none")
        }
      }

      dynamic "lambda_function_association" {
        for_each = coalesce(lookup(cache, "lambda_function_associations", []), [])
        iterator = lambda

        content {
          event_type = lambda.event_type
          lambda_arn = lambda.lambda_arn
        }
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    iterator = err_response
    content {
      error_code         = err_response.value.error_code
      response_code      = err_response.value.response_code
      response_page_path = err_response.value.response_page_path
    }
  }

  dynamic "logging_config" {
    for_each = var.logging_config == null ? [] : [var.logging_config]
    iterator = config
    content {
      bucket = config.value.bucket
      prefix = config.value.prefix
    }
  }
}
