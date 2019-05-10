# Create a REST API Gateway
resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "${var.solution_tag}_api"
  description = "API Gateway to ${var.solution_name}"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.rest_api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.rest_api.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_target" {
  rest_api_id             = "${aws_api_gateway_rest_api.rest_api.id}"
  resource_id             = "${aws_api_gateway_method.proxy_method.resource_id}"
  http_method             = "${aws_api_gateway_method.proxy_method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambda.invoke_arn}"

  depends_on = ["aws_lambda_function.lambda"]
}

resource "aws_api_gateway_method" "proxy_method_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.rest_api.id}"
  resource_id   = "${aws_api_gateway_rest_api.rest_api.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_target_root" {
  rest_api_id             = "${aws_api_gateway_rest_api.rest_api.id}"
  resource_id             = "${aws_api_gateway_method.proxy_method_root.resource_id}"
  http_method             = "${aws_api_gateway_method.proxy_method_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambda.invoke_arn}"

  depends_on = ["aws_lambda_function.lambda"]
}

resource "aws_api_gateway_deployment" "deployment_production" {
  depends_on = [
    "aws_api_gateway_integration.lambda_target",
    "aws_api_gateway_integration.lambda_target_root"
  ]

  rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
  stage_name  = "production"
}

# resource "aws_api_gateway_stage" "stage_production" {
#   stage_name    = "${aws_api_gateway_deployment.deployment_production.stage_name}"
#   rest_api_id   = "${aws_api_gateway_rest_api.rest_api.id}"
#   deployment_id = "${aws_api_gateway_deployment.deployment_production.id}"
# }

# Enable logging and rate limit
resource "aws_api_gateway_method_settings" "general_settings" {
  rest_api_id = "${aws_api_gateway_rest_api.rest_api.id}"
  stage_name  = "${aws_api_gateway_deployment.deployment_production.stage_name}"
  # method_path = "${aws_api_gateway_resource.__name__.path_part}/${aws_api_gateway_method.__name__.http_method}"
  method_path = "*/*"

  settings {
    # In order to enable logging to CloudWatch from API Gateway, an "account"
    # for the latter must be enabled and granted proper permissions. Such
    # settings are *region-wide* and cannot be limited to this application.
    # Considered the impact on your AWS account, I chose not to enable them
    # by default. Please see the docs for details.
    # metrics_enabled        = false
    # data_trace_enabled     = false
    # logging_level          = "ERROR"

    # Limit the rate of calls to prevent abuse and unwanted charges!
    throttling_rate_limit  = 100
    throttling_burst_limit = 50
  }
}
