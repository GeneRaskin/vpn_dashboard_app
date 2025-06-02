resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [
      var.allowed_origin
    ]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.lambda_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_config_route" {
  api_id = aws_apigatewayv2_api.this.id
  route_key = "GET /config"
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "options_route" {
  api_id = aws_apigatewayv2_api.this.id
  route_key = "OPTIONS /config"
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}" 
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
