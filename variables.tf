# See https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html for additional 
# configuration information.
variable "openapi_config" {
  description = "The OpenAPI specification for the API"
  type        = any
  default     = {}
}

variable "endpoint_type" {
  type        = list(string)
  description = "The type of the endpoint. One of - PUBLIC, PRIVATE, REGIONAL"
  default     = ["REGIONAL"]

  # validation {
  #   condition     = contains(["EDGE", "REGIONAL", "PRIVATE"], var.endpoint_type)
  #   error_message = "Valid values for var: endpoint_type are (EDGE, REGIONAL, PRIVATE)."
  # }
}

variable "logging_level" {
  type        = string
  description = "The logging level of the API. One of - OFF, INFO, ERROR"
  default     = "INFO"

  validation {
    condition     = contains(["OFF", "INFO", "ERROR"], var.logging_level)
    error_message = "Valid values for var: logging_level are (OFF, INFO, ERROR)."
  }
}

variable "metrics_enabled" {
  description = "A flag to indicate whether to enable metrics collection."
  type        = bool
  default     = false
}

variable "xray_tracing_enabled" {
  description = "A flag to indicate whether to enable X-Ray tracing."
  type        = bool
  default     = false
}

# See https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html for additional information
# on how to configure logging.
variable "access_log_format" {
  description = "The format of the access log file."
  type        = string
  default     = <<EOF
  {
	"requestTime": "$context.requestTime",
	"requestId": "$context.requestId",
	"httpMethod": "$context.httpMethod",
	"path": "$context.path",
	"resourcePath": "$context.resourcePath",
	"status": $context.status,
	"responseLatency": $context.responseLatency,
  "xrayTraceId": "$context.xrayTraceId",
  "integrationRequestId": "$context.integration.requestId",
	"functionResponseStatus": "$context.integration.status",
  "integrationLatency": "$context.integration.latency",
	"integrationServiceStatus": "$context.integration.integrationStatus",
  "authorizeResultStatus": "$context.authorize.status",
	"authorizerServiceStatus": "$context.authorizer.status",
	"authorizerLatency": "$context.authorizer.latency",
	"authorizerRequestId": "$context.authorizer.requestId",
  "ip": "$context.identity.sourceIp",
	"userAgent": "$context.identity.userAgent",
	"principalId": "$context.authorizer.principalId",
	"cognitoUser": "$context.identity.cognitoIdentityId",
  "user": "$context.identity.user"
}
  EOF
}

# See https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-resource-policies.html for additional
# information on how to configure resource policies.
#
# Example:
# {
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Principal": "*",
#            "Action": "execute-api:Invoke",
#            "Resource": "arn:aws:execute-api:us-east-1:000000000000:*"
#        },
#        {
#            "Effect": "Deny",
#            "Principal": "*",
#            "Action": "execute-api:Invoke",
#            "Resource": "arn:aws:execute-api:region:account-id:*",
#            "Condition": {
#                "NotIpAddress": {
#                    "aws:SourceIp": "123.4.5.6/24"
#                }
#            }
#        }
#    ]
#}
variable "rest_api_policy" {
  description = "The IAM policy document for the API."
  type        = string
  default     = null
}

variable "private_link_target_arns" {
  type        = list(string)
  description = "A list of target ARNs for VPC Private Link"
  default     = []
}

variable "iam_tags_enabled" {
  type        = string
  description = "Enable/disable tags on IAM roles and policies"
  default     = true
}

variable "permissions_boundary" {
  type        = string
  default     = ""
  description = "ARN of the policy that is used to set the permissions boundary for the IAM role"
}

variable "stage_name" {
  type        = string
  default     = ""
  description = "The name of the stage"
}


variable "create_api_gateway_deployment" {
  type        = bool
  default     = false
  description = "Create API Gateway Deployment"
}

variable "create_api_gateway_stage" {
  type        = bool
  default     = false
  description = "Create API Gateway Stage"
}

variable "vpc_link_enabled" {
  type        = bool
  default     = false
  description = "Enable VPC Link"
}

variable "vpc_link_name" {
  type        = string
  default     = ""
  description = "Name of the VPC Link"
}

variable "vpc_link_description" {
  type        = string
  default     = ""
  description = "Description of the VPC Link"
}

variable "description" {
  type        = string
  default     = ""
  description = "Description of the API Gateway"
}

variable "body" {
  type        = string
  default     = ""
  description = "The OpenAPI specification of the API Gateway"
}

variable "stage_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to be applied to the stage"
}

variable "stage_variables" {
  type        = map(string)
  default     = {}
  description = "Stage variables to be applied to the stage"
}

variable "access_log_settings" {
  type        = list(any)
  default     = []
  description = "Access log settings for the stage"
}

variable "method_path" {
  type        = string
  default     = ""
  description = "The path of the method in API Gateway"
}

variable "cache_data_encrypted" {
  type        = bool
  default     = false
  description = "Enable encryption of cache data"
}

variable "cache_ttl_in_seconds" {
  type        = number
  default     = 300
  description = "The time-to-live (TTL) period, in seconds, that specifies how long API Gateway caches responses"
}

variable "caching_enabled" {
  type        = bool
  default     = false
  description = "Enable caching of responses"
}

variable "data_trace_enabled" {
  type        = bool
  default     = false
  description = "Enable data tracing for API Gateway"
}

variable "require_authorization_for_cache_control" {
  type        = bool
  default     = false
  description = "Enable authorization for cache control"
}

variable "throttling_burst_limit" {
  type        = number
  default     = 5000
  description = "The API request burst limit"
}

variable "throttling_rate_limit" {
  type        = number
  default     = 10000
  description = "The API request steady-state rate limit"
}

variable "unauthorized_cache_control_header_strategy" {
  type        = string
  default     = "SUCCEED_WITH_RESPONSE_HEADER"
  description = "The cache control header strategy for unauthorized responses"
}

variable "create_api_gateway_method_settings" {
  type        = bool
  default     = false
  description = "Create API Gateway Method Settings"
}
