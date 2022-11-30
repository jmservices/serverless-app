# Logs
resource "aws_cloudwatch_log_group" "function_logs" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 1

  lifecycle {
    prevent_destroy = false
  }

  tags = local.tags
}


## Alerts

# Monitor lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda" {
  alarm_name                = lower(format("%s_lambda_errors", var.project_name))
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  threshold                 = "1"
  alarm_description         = "This metric monitors lambda function errors."
  insufficient_data_actions = []

  metric_query {
    id = "lambda_errors"
    return_data = true

    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        FunctionName = aws_lambda_function.this.function_name
      }
    }
  }
}

# Monitor 5XX responses
resource "aws_cloudwatch_metric_alarm" "api_gateway_5XX" {
  alarm_name                = lower(format("%s_api_gateway_5XX", var.project_name))
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  threshold                 = "1"
  alarm_description         = "This metric monitors api gateway 5XX responses."
  insufficient_data_actions = []

  metric_query {
    id = "api_5XX_responses"
    return_data = true

    metric {
      metric_name = "5XXError"
      namespace   = "AWS/ApiGateway"
      period      = "60"
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        ApiName = aws_api_gateway_rest_api.api.name
      }
    }
  }
}

# Monitor 4XX responses
resource "aws_cloudwatch_metric_alarm" "api_gateway_4XX" {
  alarm_name                = lower(format("%s_api_gateway_4XX", var.project_name))
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  threshold                 = "50"
  alarm_description         = "This metric monitors api gateway 4XX responses."
  insufficient_data_actions = []

  metric_query {
    id = "api_4XX_responses"
    return_data = true

    metric {
      metric_name = "4XXError"
      namespace   = "AWS/ApiGateway"
      period      = "60"
      stat        = "Average"
      unit        = "Count"

      dimensions = {
        ApiName = aws_api_gateway_rest_api.api.name
      }
    }
  }
}