resource "aws_apigatewayv2_api" "fitai" {
  name          = "${var.project_name}-${var.environment}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_vpc_link" "fitai" {
  name               = "${var.project_name}-${var.environment}-link"
  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.api_gateway_link.id]
}

resource "aws_apigatewayv2_integration" "app" {
  api_id                 = aws_apigatewayv2_api.fitai.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = aws_lb_listener.internal_http.arn
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.fitai.id
  payload_format_version = "1.0"

  request_parameters = {
    "overwrite:path" = "$request.path"
  }

  depends_on = [
    aws_vpc_security_group_ingress_rule.alb_from_api_gateway,
    aws_vpc_security_group_egress_rule.api_gateway_to_alb
  ]
}

resource "aws_apigatewayv2_route" "health" {
  api_id             = aws_apigatewayv2_api.fitai.id
  route_key          = "GET /health"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_route" "list_workouts" {
  api_id             = aws_apigatewayv2_api.fitai.id
  route_key          = "GET /workouts"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_route" "create_workout" {
  api_id             = aws_apigatewayv2_api.fitai.id
  route_key          = "POST /workouts"
  authorization_type = "AWS_IAM"
  target             = "integrations/${aws_apigatewayv2_integration.app.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.fitai.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn

    format = jsonencode({
      requestId         = "$context.requestId"
      status            = "$context.status"
      integrationStatus = "$context.integration.status"
      integrationError  = "$context.integrationErrorMessage"
      error             = "$context.error.message"
    })
  }
} 
