resource "aws_api_gateway_rest_api" "api" {
  name = "${var.project}-api"

  body = templatefile("${path.module}/openapi/openapi.yaml", {
  region           = var.aws_region
  create_order_arn = aws_lambda_function.create_order.arn
  get_order_arn    = aws_lambda_function.get_order.arn
  list_orders_arn  = aws_lambda_function.list_orders.arn
})

}


resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeploy = sha1(templatefile("${path.module}/openapi/openapi.yaml", {
      region           = var.aws_region
      create_order_arn = aws_lambda_function.create_order.arn
      get_order_arn    = aws_lambda_function.get_order.arn
      list_orders_arn  = aws_lambda_function.list_orders.arn
    }))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "prod" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  deployment_id        = aws_api_gateway_deployment.deploy.id
  stage_name           = "prod"
  xray_tracing_enabled = true
}

resource "aws_api_gateway_api_key" "client_key" {
  name    = "${var.project}-client-key"
  enabled = true
}

resource "aws_api_gateway_usage_plan" "plan" {
  name = "${var.project}-usage-plan"
  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }
  throttle_settings {
    rate_limit  = 10
    burst_limit = 20
  }
}

resource "aws_api_gateway_usage_plan_key" "plan_key" {
  key_id        = aws_api_gateway_api_key.client_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.plan.id
}

# Allow API Gateway to invoke lambdas
resource "aws_lambda_permission" "apigw_create" {
  statement_id  = "AllowAPIGWInvokeCreate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
resource "aws_lambda_permission" "apigw_get" {
  statement_id  = "AllowAPIGWInvokeGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_order.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
resource "aws_lambda_permission" "apigw_list" {
  statement_id  = "AllowAPIGWInvokeList"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_orders.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
