variable "env" {
  description = "Environment name where API Gatway will be created (e.g., dev, qa, shared, stage, prod)."
  type        = string
}

variable "stage" {
  description = "Apigateway stage name"
  type        = string
  default     = "prod"
}

variable "name" {
  description = "The name of the API. Must be less than or equal to 128 characters in length"
  type        = string
}

variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "create_custom_domain" {
  description = "Controls if custom domain should be created"
  type        = bool
  default     = false
}

variable "existing_custom_domain" {
  description = "Controls if use an existing custom domain"
  type        = bool
  default     = false
}

variable "subdomain_name" {
  description = "The name of the API custom subdomain name. Must be less than or equal to 128 characters in length"
  type        = string
  default     = ""
}

variable "existing_domain_name" {
  description = "The name of the existing API custom subdomain name. Must be less than or equal to 128 characters in length"
  type        = string
  default     = ""
}

variable "apigw_policy_json" {
  default = ""
  type = string
}

variable "base_path" {
  description = "The base path used when mapping this API to a shared custom domain (e.g., 'users', 'orders'). Must be 128 characters or fewer."
  type        = string
  default     = ""
}

variable "xray_tracing_enabled" {
  description = "Whether active tracing with X-ray is enabled"
  type        = bool
  default     = false
}

variable "access_logs_enabled" {
  description = "Whether active tracing with X-ray is enabled"
  type        = bool
  default     = false
}

variable "allowed_ips" {
  description = "List of ips allowed to invoke API"
  type        = list(string)
  default     = []
}

variable "description" {
  description = "The description of the API. Must be less than or equal to 1024 characters in length"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 14
}

variable "tags" {
  description = "A mapping of tags to assign to API gateway resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Route(s) & Integration(s)
################################################################################

variable "routes" {
  description = "Map of API Gateway paths with shared integration and methods"
  type = map(object({
    method             = list(string)
    integration_method = optional(string)
    route_settings = optional(object({
      # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings#argument-reference
      metrics_enabled        = optional(bool, false)
      data_trace_enabled     = optional(bool, false)
      logging_level          = optional(string, "INFO")
      throttling_rate_limit  = optional(number, -1)
      throttling_burst_limit = optional(number, -1)
    }))
    integration = object({
      # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration#argument-reference
      authorization_type             = optional(string, "NONE")
      uri                            = string
      connection_type                = optional(string, "INTERNET")
      credentials_arn                = optional(string)
      description                    = optional(string)
      type                           = optional(string, "AWS_PROXY")
      method_request_parameters      = optional(map(string), {})
      integration_request_parameters = optional(map(string), {})
      request_templates              = optional(map(string), {})
      content_handling_strategy      = optional(string)
      passthrough_behavior           = optional(string, "WHEN_NO_MATCH")
      timeout_milliseconds           = optional(number, 29000)
    })
  }))
  default = {}
}

variable "default_method_settings" {
  description = "Map of method paths to method settings"
  type = object({
    metrics_enabled        = optional(bool, true)
    data_trace_enabled     = optional(bool, true)
    logging_level          = optional(string, "ERROR")
    throttling_rate_limit  = optional(number, -1)
    throttling_burst_limit = optional(number, -1)
  })
  default = {
    metrics_enabled        = true
    data_trace_enabled     = true
    logging_level          = "ERROR"
    throttling_rate_limit  = -1
    throttling_burst_limit = -1
  }
}

variable "custom_access_log_format" {
  description = "Access log settings for the stage"
  type        = string
  default     = ""
}
