resource "aws_api_gateway_rest_api" "api" {
  name = format("%s api gateway", var.project_name)

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.tags

}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "hello"

  depends_on = [
    aws_api_gateway_rest_api.api
  ]
}

resource "aws_api_gateway_resource" "api_resource" {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{username}"
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [aws_api_gateway_rest_api.api]
}

resource "aws_api_gateway_method" "put" {
  authorization = "NONE"
  http_method   = "PUT"
  resource_id   = aws_api_gateway_resource.api_resource.id
  rest_api_id   = aws_api_gateway_rest_api.api.id

  request_parameters   = {
    "method.request.path.username" = true
  }

  depends_on = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api_resource]
}

resource "aws_api_gateway_method" "get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.api_resource.id
  rest_api_id   = aws_api_gateway_rest_api.api.id

  request_parameters   = {
    "method.request.path.username" = true
  }


  depends_on = [aws_api_gateway_rest_api.api, aws_api_gateway_resource.api_resource]
}

resource "aws_api_gateway_integration" "put_integration" {
  http_method             = aws_api_gateway_method.put.http_method
  resource_id             = aws_api_gateway_resource.api_resource.id
  rest_api_id             = aws_api_gateway_rest_api.api.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.this.invoke_arn

  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_resource.api_resource,
    aws_api_gateway_method.put,
    aws_lambda_function.this
  ]
}

resource "aws_api_gateway_method_response" "get_method_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_resource.api_resource,
    aws_api_gateway_method.get,
    aws_lambda_function.this
  ]
}

resource "aws_api_gateway_method_response" "put_method_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.put.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_resource.api_resource,
    aws_api_gateway_method.put,
    aws_lambda_function.this
  ]
}

resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = aws_api_gateway_method_response.get_method_response.status_code

  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_resource.api_resource,
    aws_api_gateway_method.get,
    aws_api_gateway_method_response.get_method_response,
    aws_lambda_function.this
  ]
}

resource "aws_api_gateway_integration_response" "put_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.api_resource.id
  http_method = aws_api_gateway_method.put.http_method
  status_code = aws_api_gateway_method_response.put_method_response.status_code

  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_resource.api_resource,
    aws_api_gateway_method.put,
    aws_api_gateway_method_response.get_method_response,
    aws_lambda_function.this
  ]
}

resource "aws_api_gateway_integration" "get_integration" {
  http_method             = aws_api_gateway_method.get.http_method
  resource_id             = aws_api_gateway_resource.api_resource.id
  rest_api_id             = aws_api_gateway_rest_api.api.id
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.this.invoke_arn

  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_api_gateway_resource.api_resource,
    aws_api_gateway_method.get,
    aws_lambda_function.this
  ]
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.api.id,
      aws_api_gateway_resource.api_resource.id,
      aws_api_gateway_method.put.id,
      aws_api_gateway_method_response.put_method_response.id,
      aws_api_gateway_method_response.get_method_response.id,
      aws_api_gateway_integration_response.put_integration_response.id,
      aws_api_gateway_integration_response.get_integration_response.id,
      aws_api_gateway_integration.put_integration.id,
      aws_api_gateway_method.get.id,
      aws_api_gateway_integration.get_integration.id,
      aws_lambda_permission.allow_apigateway_trigger_get,
      aws_lambda_permission.allow_apigateway_trigger_put
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
