# Terraform Module: tf-module-apigateway

## Description
Terraform Module for managing a fully configurable AWS API Gateway (REST API) infrastructure,
including resources, methods, integrations, stages, deployments, logging, custom domains, and optional Route53 DNS setup.
Designed for flexible use across environments with support for fine-grained method settings, custom logging formats, and conditional resource creation.

## Usage

```hcl
module "flexible_apigw" {
  source = ""

  routes = {
    "/users" = {
      method = ["GET", "POST", "OPTIONS"]
      integration = {
        uri = "lambda_uri"
      }
    }

    "/users/{userId+}" = {
      method = ["GET", "OPTIONS"]
      integration = {
        uri = "lambda_uri"
        method_request_parameters = {
          "method.request.path.userId" = true
        }
      }
    }

    "/users/ui/{component}/metadata" = {
      method = ["GET", "POST", "OPTIONS"]
      integration = {
        uri = "lambda_uri"
      }
    }
    "/orders" = {
      method = ["GET", "POST", "OPTIONS"]
      integration = {
        uri = "lambda_uri"
      }
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5.79 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.98.0 |

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_base_path_mapping._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_base_path_mapping) | resource |
| [aws_api_gateway_deployment._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_domain_name._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_domain_name) | resource |
| [aws_api_gateway_integration._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_method._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_settings.default_settings](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_method_settings.per_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_resource.level1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level5](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_resource.level7](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource) | resource |
| [aws_api_gateway_rest_api._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_rest_api_policy._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api_policy) | resource |
| [aws_api_gateway_stage._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_iam_policy_document.api_policy_doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs_enabled"></a> [access\_logs\_enabled](#input\_access\_logs\_enabled) | Whether active tracing with X-ray is enabled | `bool` | `false` | no |
| <a name="input_allowed_ips"></a> [allowed\_ips](#input\_allowed\_ips) | List of ips allowed to invoke API | `list(string)` | `[]` | no |
| <a name="input_create"></a> [create](#input\_create) | Controls if resources should be created | `bool` | `true` | no |
| <a name="input_create_custom_domain"></a> [create\_custom\_domain](#input\_create\_custom\_domain) | Controls if custom domain should be created | `bool` | `false` | no |
| <a name="input_custom_access_log_format"></a> [custom\_access\_log\_format](#input\_custom\_access\_log\_format) | Access log settings for the stage | `string` | `""` | no |
| <a name="input_default_method_settings"></a> [default\_method\_settings](#input\_default\_method\_settings) | Map of method paths to method settings | <pre>object({<br/>    metrics_enabled        = optional(bool, true)<br/>    data_trace_enabled     = optional(bool, true)<br/>    logging_level          = optional(string, "ERROR")<br/>    throttling_rate_limit  = optional(number, -1)<br/>    throttling_burst_limit = optional(number, -1)<br/>  })</pre> | <pre>{<br/>  "data_trace_enabled": true,<br/>  "logging_level": "ERROR",<br/>  "metrics_enabled": true,<br/>  "throttling_burst_limit": -1,<br/>  "throttling_rate_limit": -1<br/>}</pre> | no |
| <a name="input_description"></a> [description](#input\_description) | The description of the API. Must be less than or equal to 1024 characters in length | `string` | `null` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment name where API Gatway will be created (e.g., dev, qa, shared, stage, prod). | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain logs | `number` | `14` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the API. Must be less than or equal to 128 characters in length | `string` | n/a | yes |
| <a name="input_routes"></a> [routes](#input\_routes) | Map of API Gateway paths with shared integration and methods | <pre>map(object({<br/>    method = list(string)<br/>    route_settings = optional(object({<br/>      # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings#argument-reference<br/>      metrics_enabled        = optional(bool, false)<br/>      data_trace_enabled     = optional(bool, false)<br/>      logging_level          = optional(string, "INFO")<br/>      throttling_rate_limit  = optional(number, -1)<br/>      throttling_burst_limit = optional(number, -1)<br/>    }))<br/>    integration = object({<br/>      # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration#argument-reference<br/>      authorization_type             = optional(string, "NONE")<br/>      uri                            = string<br/>      connection_type                = optional(string, "INTERNET")<br/>      credentials_arn                = optional(string)<br/>      description                    = optional(string)<br/>      type                           = optional(string, "AWS_PROXY")<br/>      method_request_parameters      = optional(map(string), {})<br/>      integration_method             = optional(string, "POST")<br/>      integration_request_parameters = optional(map(string), {})<br/>      request_templates              = optional(map(string), {})<br/>      content_handling_strategy      = optional(string)<br/>      passthrough_behavior           = optional(string, "WHEN_NO_MATCH")<br/>      timeout_milliseconds           = optional(number, 10000)<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_subdomain_name"></a> [subdomain\_name](#input\_subdomain\_name) | The name of the API custom subdomain name. Must be less than or equal to 128 characters in length | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to API gateway resources | `map(string)` | `{}` | no |
| <a name="input_xray_tracing_enabled"></a> [xray\_tracing\_enabled](#input\_xray\_tracing\_enabled) | Whether active tracing with X-ray is enabled | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_arn"></a> [api\_arn](#output\_api\_arn) | The ARN of the REST API |
| <a name="output_api_execution_arn"></a> [api\_execution\_arn](#output\_api\_execution\_arn) | The execution ARN to use in Lambda permissions (source\_arn) |
| <a name="output_api_id"></a> [api\_id](#output\_api\_id) | The ID of the REST API |
| <a name="output_api_root_resource_id"></a> [api\_root\_resource\_id](#output\_api\_root\_resource\_id) | The root resource ID of the REST API |
<!-- END_TF_DOCS -->
