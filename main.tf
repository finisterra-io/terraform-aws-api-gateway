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
  for_each    = var.deployments
  rest_api_id = aws_api_gateway_rest_api.this[0].id
  description = try(each.value.description, "")

  # triggers = {
  #   redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this[0].body))
  # }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "this" {
  # Create a flattened list of all stages in all deployments, accounting for deployments without stages
  for_each = { for idx, value in flatten([
    for deployment_id, deployment in var.deployments : [
      for stage_id, stage in try(deployment.stages, {}) : { # Use try to handle missing stages
        deployment_id = deployment_id
        stage_id      = stage_id
        stage         = stage
      }
    ]
  ]) : "${value.deployment_id}-${value.stage_id}" => value }

  deployment_id         = aws_api_gateway_deployment.this[each.value.deployment_id].id
  rest_api_id           = aws_api_gateway_rest_api.this[0].id
  stage_name            = each.value.stage_id
  xray_tracing_enabled  = each.value.stage.xray_tracing_enabled
  cache_cluster_enabled = each.value.stage.cache_cluster_enabled
  cache_cluster_size    = try(each.value.stage.cache_cluster_size, null)
  description           = try(each.value.stage.description, "")

  tags = try(each.value.stage.tags, {})

  variables = try(each.value.stage.variables, null)

  dynamic "access_log_settings" {
    for_each = try(each.value.stage.access_log_settings, [])

    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = replace(access_log_settings.value.format, "\n", "")
    }
  }
}


# Set the logging, metrics and tracing levels for all methods
resource "aws_api_gateway_method_settings" "all" {
  for_each = local.enabled ? var.api_gateway_method_settings : {}

  rest_api_id = aws_api_gateway_rest_api.this[0].id
  stage_name  = each.value.stage_name
  method_path = each.value.method_path

  settings {
    cache_data_encrypted                       = each.value.cache_data_encrypted
    cache_ttl_in_seconds                       = each.value.cache_ttl_in_seconds
    caching_enabled                            = each.value.caching_enabled
    data_trace_enabled                         = each.value.data_trace_enabled
    logging_level                              = each.value.logging_level
    metrics_enabled                            = each.value.metrics_enabled
    require_authorization_for_cache_control    = each.value.require_authorization_for_cache_control
    throttling_burst_limit                     = each.value.throttling_burst_limit
    throttling_rate_limit                      = each.value.throttling_rate_limit
    unauthorized_cache_control_header_strategy = each.value.unauthorized_cache_control_header_strategy
  }
}

# Optionally create a VPC Link to allow the API Gateway to communicate with private resources (e.g. ALB)
resource "aws_api_gateway_vpc_link" "this" {
  count       = var.vpc_link_enabled ? 1 : 0
  name        = var.vpc_link_name
  description = var.vpc_link_description
  target_arns = var.private_link_target_arns
}
