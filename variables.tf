variable "name" {
  type = string
}

variable "enabled" {
  type    = bool
  default = true
}

variable "is_ipv6_enabled" {
  type    = bool
  default = true
}

variable "custom_domain_name" {
  type = string
}

variable "default_root_object" {
  type    = string
  default = null
}

variable "logging_config" {
  type    = map(any)
  default = null
}

variable "origins" {
  type = list(object({
    origin_id   = string
    domain_name = string
    s3_origin_config = optional(object({
      origin_access_identity    =  string
    }))
    custom_origin_config = optional(object({
      http_port                = number
      https_port               = number
      origin_protocol_policy   = string
      origin_ssl_protocols     = list(string)
      origin_keepalive_timeout = number
      origin_read_timeout      = number
    }))
  }))
}

variable "ordered_cache_behaviors" {
  type = list(object({
    origin_id           = string
    allowed_methods     = optional(list(string))
    cached_methods      = optional(list(string))
    path_pattern        = string
    ttl_policy          = string
    custom_cache_config = optional(map(any))
    lambda_function_associations = optional(list(object({
      event_type = string
      lambda_arn = string
    })))
    forwarded_query_string = optional(bool)
    forwarded_headers      = optional(list(string))
    forwarded_cookies      = optional(string)
  }))
  default = []
}

variable "default_cache_behavior" {
  type = object({
    origin_id           = string
    allowed_methods     = optional(list(string))
    cached_methods      = optional(list(string))
    ttl_policy          = string
    custom_cache_config = optional(map(any))
    lambda_function_associations = optional(list(object({
      event_type = string
      lambda_arn = string
    })))
    forwarded_query_string = optional(bool)
    forwarded_headers      = optional(list(string))
    forwarded_cookies      = optional(string)
  })
}

variable "custom_error_responses" {
  type = list(object({
    error_code         = number
    response_code      = number
    response_page_path = string
  }))
  default = []
}

variable "viewer_certificate_arn" {
  type = string
}
