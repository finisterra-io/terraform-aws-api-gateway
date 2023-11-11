locals {
  enabled                = module.this.enabled
  create_rest_api_policy = local.enabled && var.rest_api_policy != null
  # create_log_group       = local.enabled && var.logging_level != "OFF"
  # log_group_arn          = local.create_log_group ? module.cloudwatch_log_group.log_group_arn : null
  vpc_link_enabled = local.enabled && length(var.private_link_target_arns) > 0
}

resource "aws_api_gateway_rest_api" "this" {
  count = local.enabled ? 1 : 0

  name        = var.name
  description = var.description
  body        = try(var.body, null)
  tags        = var.tags

  endpoint_configuration {
    types = var.endpoint_type
  }
}

resource "aws_api_gateway_rest_api_policy" "this" {
  count       = local.create_rest_api_policy ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id

  policy = var.rest_api_policy
}

# module "cloudwatch_log_group" {
#   source  = "cloudposse/cloudwatch-logs/aws"
#   version = "0.6.5"

#   enabled              = local.create_log_group
#   iam_tags_enabled     = var.iam_tags_enabled
#   permissions_boundary = var.permissions_boundary

#   context = module.this.context
# }

resource "aws_api_gateway_deployment" "this" {
  count       = local.enabled && var.create_api_gateway_deployment ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id

  # triggers = {
  #   redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this[0].body))
  # }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  count                 = local.enabled && var.create_api_gateway_stage ? 1 : 0
  deployment_id         = aws_api_gateway_deployment.this[0].id
  rest_api_id           = aws_api_gateway_rest_api.this[0].id
  stage_name            = var.stage_name != "" ? var.stage_name : module.this.stage
  xray_tracing_enabled  = var.xray_tracing_enabled
  cache_cluster_enabled = var.stage_cache_cluster_enabled
  cache_cluster_size    = var.stage_cache_cluster_size
  description           = var.stage_description

  tags = var.stage_tags

  variables = var.stage_variables

  # variables = {
  #   vpc_link_id = local.vpc_link_enabled ? aws_api_gateway_vpc_link.this[0].id : null
  # }


  dynamic "access_log_settings" {
    for_each = var.access_log_settings

    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = replace(access_log_settings.value.format, "\n", "")
    }
  }
}

# Set the logging, metrics and tracing levels for all methods
resource "aws_api_gateway_method_settings" "all" {
  count       = local.enabled && var.create_api_gateway_stage && var.create_api_gateway_method_settings ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  stage_name  = aws_api_gateway_stage.this[0].stage_name
  method_path = var.method_path

  settings {
    cache_data_encrypted                       = var.cache_data_encrypted
    cache_ttl_in_seconds                       = var.cache_ttl_in_seconds
    caching_enabled                            = var.caching_enabled
    data_trace_enabled                         = var.data_trace_enabled
    logging_level                              = var.logging_level
    metrics_enabled                            = var.metrics_enabled
    require_authorization_for_cache_control    = var.require_authorization_for_cache_control
    throttling_burst_limit                     = var.throttling_burst_limit
    throttling_rate_limit                      = var.throttling_rate_limit
    unauthorized_cache_control_header_strategy = var.unauthorized_cache_control_header_strategy
  }
}

# Optionally create a VPC Link to allow the API Gateway to communicate with private resources (e.g. ALB)
resource "aws_api_gateway_vpc_link" "this" {
  count       = var.vpc_link_enabled ? 1 : 0
  name        = var.vpc_link_name
  description = var.vpc_link_description
  target_arns = var.private_link_target_arns
}
