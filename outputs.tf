output "api" {
  description = "Output REST API details."
  value       = aws_api_gateway_rest_api.api
}

output "function" {
  description = "Output Function details."
  value       = aws_lambda_function.this
}

output "db" {
  description = "Output DynamoDB table details."
  value       = aws_dynamodb_table.db
}

output "logs" {
  description = "Output CloudWatch logs details."
  value       = aws_cloudwatch_log_group.function_logs
}

output "alarms" {
  description = "Output CloudWatch alarms details."
  value       = {
    lambda_errors = aws_cloudwatch_metric_alarm.lambda.alarm_name
    api_5XX = aws_cloudwatch_metric_alarm.api_gateway_5XX.alarm_name
    api_4XX = aws_cloudwatch_metric_alarm.api_gateway_4XX.alarm_name
  }
}
