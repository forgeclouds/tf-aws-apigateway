################################################################################
# Locals
################################################################################

locals {
  normalized_routes = var.create ? {
    # {
    #   "users/GET" = {
    #     full_path          = "users"
    #     key                = "users/GET"
    #     method             = "GET"
    #     integration_method = "GET"
    #     integration        = {
    #       uri = "arn:aws:lambda:::users-lambda"
    #     }
    #     route_settings     = null
    #   }
    #
    #   "users/POST" = {
    #     full_path          = "users"
    #     key                = "users/POST"
    #     method             = "POST"
    #     integration_method = "POST"
    #     integration        = {
    #       uri = "arn:aws:lambda:::users-lambda"
    #     }
    #     route_settings     = null
    #   }
    #
    #   "users/{userId+}/GET" = {
    #     full_path          = "users/{userId+}"
    #     key                = "users/{userId+}/GET"
    #     method             = "GET"
    #     integration_method = "GET"
    #     integration        = {
    #       uri = "arn:aws:lambda:::users-lambda"
    #       method_request_parameters = {
    #         "method.request.path.userId" = true
    #       }
    #     }
    #     route_settings     = null
    #   }
    #
    #   "users/ui/{component}/metadata/GET" = {
    #     full_path          = "users/ui/{component}/metadata"
    #     key                = "users/ui/{component}/metadata/GET"
    #     method             = "GET"
    #     integration_method = "GET"
    #     integration        = {
    #       uri = "arn:aws:lambda:::users-lambda"
    #     }
    #     route_settings     = null
    #   }
    #
    #   "users/ui/{component}/metadata/POST" = {
    #     full_path          = "users/ui/{component}/metadata"
    #     key                = "users/ui/{component}/metadata/POST"
    #     method             = "POST"
    #     integration_method = "POST"
    #     integration        = {
    #       uri = "arn:aws:lambda:::users-lambda"
    #     }
    #     route_settings     = null
    #   }
    #
    #   "orders/GET" = {
    #     full_path          = "orders"
    #     key                = "orders/GET"
    #     method             = "GET"
    #     integration_method = "GET"
    #     integration        = {
    #       uri = "arn:aws:lambda:::orders-lambda"
    #     }
    #     route_settings     = null
    #   }
    #
    #   "orders/POST" = {
    #     full_path          = "orders"
    #     key                = "orders/POST"
    #     method             = "POST"
    #     integration_method = "POST"
    #     integration        = {
    #       uri = "arn:aws:lambda:::orders-lambda"
    #     }
    #     route_settings     = null
    #   }
    # }
    for pair in flatten([
      for path, config in var.routes : [
        for m in config.method : {
          key    = "${trim(path, "/")}/${upper(m)}"
          path   = trim(path, "/")
          method = upper(m)
          config = config
        }
      ]
    ]) :
    pair.key => {
      full_path          = pair.path
      key                = pair.key
      method             = pair.method
      integration_method = pair.method != "OPTIONS" ? pair.method : null
      integration = pair.method == "OPTIONS" ? {
        authorization_type             = "NONE"
        uri                            = null
        connection_type                = null
        credentials_arn                = null
        description                    = "CORS support"
        type                           = "MOCK"
        method_request_parameters      = {}
        integration_request_parameters = {}
        request_templates              = { "application/json" = "{\"statusCode\": 200}" }
        content_handling_strategy      = null
        passthrough_behavior           = "WHEN_NO_MATCH"
        timeout_milliseconds           = null
      } : pair.config.integration
      route_settings = try(pair.config.route_settings, null)
    }
  } : {}

  resource_tree = var.create ? {
    # resource_tree builds a hierarchical representation of all unique path segments needed to construct nested
    # aws_api_gateway_resource blocks. It groups each segment by its full path and provides the path_part
    # (last segment) and parent_path (all segments before it), which are used to determine nesting.
    #
    # Example:
    # {
    #   "users" = {
    #     full_path   = "users"
    #     parent_path = ""
    #     path_part   = "users"
    #   }
    #
    #   "users/{userId+}" = {
    #     full_path   = "users/{userId+}"
    #     parent_path = "users"
    #     path_part   = "{userId+}"
    #   }
    #
    #   "users/ui" = {
    #     full_path   = "users/ui"
    #     parent_path = "users"
    #     path_part   = "ui"
    #   }
    #
    #   "users/ui/{component}" = {
    #     full_path   = "users/ui/{component}"
    #     parent_path = "users/ui"
    #     path_part   = "{component}"
    #   }
    #
    #   "users/ui/{component}/metadata" = {
    #     full_path   = "users/ui/{component}/metadata"
    #     parent_path = "users/ui/{component}"
    #     path_part   = "metadata"
    #   }
    #
    #   "orders" = {
    #     full_path   = "orders"
    #     parent_path = ""
    #     path_part   = "orders"
    #   }
    # }
    for part in flatten([
      for path in keys(var.routes) : [
        for i, p in split("/", trim(path, "/")) : {
          full_path   = join("/", slice(split("/", trim(path, "/")), 0, i + 1))
          parent_path = join("/", slice(split("/", trim(path, "/")), 0, i))
          path_part   = p
        }
      ]
    ]) :
    part.full_path => part...
  } : {}

  find_resource_id = var.create ? {
    for r in local.normalized_routes :
    r.key => coalesce(
      try(aws_api_gateway_resource.level7[r.full_path].id, null),
      try(aws_api_gateway_resource.level6[r.full_path].id, null),
      try(aws_api_gateway_resource.level5[r.full_path].id, null),
      try(aws_api_gateway_resource.level4[r.full_path].id, null),
      try(aws_api_gateway_resource.level3[r.full_path].id, null),
      try(aws_api_gateway_resource.level2[r.full_path].id, null),
      try(aws_api_gateway_resource.level1[r.full_path].id, null)
    )
  } : {}

  selected_log_format = var.custom_access_log_format != "" ? var.custom_access_log_format : local.default_log_format
  default_log_format = jsonencode({
    domainName              = "$context.domainName"
    integrationErrorMessage = "$context.integrationErrorMessage"
    protocol                = "$context.protocol"
    requestId               = "$context.requestId"
    requestTime             = "$context.requestTime"
    responseLength          = "$context.responseLength"
    routeKey                = "$context.routeKey"
    stage                   = "$context.stage"
    status                  = "$context.status"
    error = {
      message      = "$context.error.message"
      responseType = "$context.error.responseType"
    }
    identity = {
      sourceIP = "$context.identity.sourceIp"
    }
    integration = {
      error             = "$context.integration.error"
      integrationStatus = "$context.integration.integrationStatus"
    }
  })
}

################################################################################
# REST API Gateway
################################################################################

resource "aws_api_gateway_rest_api" "_" {
  count = var.create ? 1 : 0

  name        = var.name
  description = var.description

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_rest_api_policy" "_" {
  count = var.create && length(var.allowed_ips) > 1 ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api._[0].id
  policy      = var.apigw_policy_json
}

################################################################################
# API Gateway Resources - Up to 5 Nested Levels
################################################################################

resource "aws_api_gateway_resource" "level1" {
  for_each = var.create ? {
    for k, v in local.resource_tree : k => v[0] if length(split("/", k)) == 1
  } : {}

  rest_api_id = aws_api_gateway_rest_api._[0].id
  parent_id   = aws_api_gateway_rest_api._[0].root_resource_id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level2" {
  for_each = var.create ? {
    for k, v in local.resource_tree : k => v[0] if length(split("/", k)) == 2
  } : {}

  rest_api_id = aws_api_gateway_rest_api._[0].id
  parent_id   = aws_api_gateway_resource.level1[each.value.parent_path].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level3" {
  for_each = var.create ? {
    for k, v in local.resource_tree : k => v[0] if length(split("/", k)) == 3
  } : {}

  rest_api_id = aws_api_gateway_rest_api._[0].id
  parent_id   = aws_api_gateway_resource.level2[each.value.parent_path].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level4" {
  for_each = var.create ? {
    for k, v in local.resource_tree : k => v[0] if length(split("/", k)) == 4
  } : {}

  rest_api_id = aws_api_gateway_rest_api._[0].id
  parent_id   = aws_api_gateway_resource.level3[each.value.parent_path].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level5" {
  for_each = var.create ? {
    for k, v in local.resource_tree : k => v[0] if length(split("/", k)) == 5
  } : {}

  rest_api_id = aws_api_gateway_rest_api._[0].id
  parent_id   = aws_api_gateway_resource.level4[each.value.parent_path].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level6" {
  for_each = var.create ? {
    for k, v in local.resource_tree : k => v[0] if length(split("/", k)) == 6
  } : {}

  rest_api_id = aws_api_gateway_rest_api._[0].id
  parent_id   = aws_api_gateway_resource.level5[each.value.parent_path].id
  path_part   = each.value.path_part
}

resource "aws_api_gateway_resource" "level7" {
  for_each = var.create ? {
    for k, v in local.resource_tree : k => v[0] if length(split("/", k)) == 7
  } : {}

  rest_api_id = aws_api_gateway_rest_api._[0].id
  parent_id   = aws_api_gateway_resource.level6[each.value.parent_path].id
  path_part   = each.value.path_part
}

################################################################################
# Methods and Integrations
################################################################################

resource "aws_api_gateway_method" "_" {
  for_each = local.normalized_routes

  rest_api_id   = aws_api_gateway_rest_api._[0].id
  resource_id   = local.find_resource_id[each.key]
  http_method   = each.value.method
  authorization = try(each.value.integration.authorization_type, null)

  request_parameters = try(each.value.integration.method_request_parameters, null)
}

resource "aws_api_gateway_integration" "_" {
  for_each = var.create ? local.normalized_routes : {}

  rest_api_id             = aws_api_gateway_rest_api._[0].id
  resource_id             = local.find_resource_id[each.key]
  type                    = each.value.integration.type
  uri                     = each.value.integration.uri
  http_method             = each.value.method
  integration_http_method = each.value.integration_method
  passthrough_behavior    = each.value.integration.passthrough_behavior
  timeout_milliseconds    = each.value.integration.timeout_milliseconds
  request_templates       = each.value.integration.request_templates
  request_parameters      = each.value.integration.integration_request_parameters
  content_handling        = each.value.integration.content_handling_strategy
  credentials             = each.value.integration.credentials_arn

  depends_on = [aws_api_gateway_method._]
}

resource "aws_api_gateway_integration_response" "_" {
  for_each = var.create ? local.normalized_routes : {}

  rest_api_id = aws_api_gateway_rest_api._[0].id
  resource_id = local.find_resource_id[each.key]
  http_method = each.value.method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,Authentication,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,DELETE,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Max-Age"       = "'600'"
  }

  response_templates = {
    "application/json" = ""
  }

  depends_on = [aws_api_gateway_method_response._]
}

resource "aws_api_gateway_method_response" "_" {
  for_each = var.create ? local.normalized_routes : {}

  rest_api_id = aws_api_gateway_rest_api._[0].id
  resource_id = local.find_resource_id[each.key]
  http_method = each.value.method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Max-Age"       = true
  }

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [aws_api_gateway_integration._, ]
}

################################################################################
# Deployment and Stage
################################################################################

resource "aws_api_gateway_deployment" "_" {
  count = var.create ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api._[0].id
  triggers = {
    redeployment = timestamp()
  }

  depends_on = [aws_api_gateway_integration._]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "_" {
  count = var.create ? 1 : 0

  stage_name           = var.stage
  xray_tracing_enabled = var.xray_tracing_enabled
  rest_api_id          = aws_api_gateway_rest_api._[0].id
  deployment_id        = aws_api_gateway_deployment._[0].id

  dynamic "access_log_settings" {
    for_each = var.access_logs_enabled ? [1] : []

    content {
      destination_arn = aws_cloudwatch_log_group.apigw_logs[0].arn
      format          = local.selected_log_format
    }
  }
}

resource "aws_cloudwatch_log_group" "apigw_logs" {
  count = var.create ? 1 : 0

  name              = "/aws/apigateway/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

################################################################################
# Method Settings
################################################################################

resource "aws_api_gateway_method_settings" "default_settings" {
  count = var.create ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api._[0].id
  stage_name  = aws_api_gateway_stage._[0].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = var.default_method_settings.metrics_enabled
    logging_level          = var.default_method_settings.logging_level
    data_trace_enabled     = var.default_method_settings.data_trace_enabled
    throttling_rate_limit  = var.default_method_settings.throttling_rate_limit
    throttling_burst_limit = var.default_method_settings.throttling_burst_limit
  }
}

resource "aws_api_gateway_method_settings" "per_route" {
  for_each = var.create ? local.normalized_routes : {}

  rest_api_id = aws_api_gateway_rest_api._[0].id
  stage_name  = aws_api_gateway_stage._[0].stage_name
  method_path = each.key

  settings {
    metrics_enabled        = try(each.value.route_settings.metrics_enabled, null)
    logging_level          = try(each.value.route_settings.logging_level, null)
    data_trace_enabled     = try(each.value.route_settings.data_trace_enabled, null)
    throttling_rate_limit  = try(each.value.route_settings.throttling_rate_limit, null)
    throttling_burst_limit = try(each.value.route_settings.throttling_burst_limit, null)
  }
}
