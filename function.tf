resource "aws_iam_role" "lambda" {
  name = format("%s_lambda_roles", var.project_name)

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = local.tags
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = format("%s_lambda_policy", var.project_name)
  role = aws_iam_role.lambda.id

  policy = file("${path.module}/files/policies/policy.json")
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "${path.module}/files/app/api.py"
  output_path = "${path.module}/files/app/api.py.zip"
}

resource "aws_lambda_function" "this" {
  filename      = data.archive_file.zip.output_path
  function_name = var.project_name
  role          = aws_iam_role.lambda.arn
  handler       = "api.lambda_handler"

  source_code_hash = data.archive_file.zip.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      dynamo_table = aws_dynamodb_table.db.name
      env = "AWS"
    }
  }

  tags = local.tags
}

resource "aws_lambda_permission" "allow_apigateway_trigger_get" {
  statement_id  = "AllowExecutionFromAPIGatewayGET"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:${aws_api_gateway_rest_api.api.id}/*/GET/*"
}

resource "aws_lambda_permission" "allow_apigateway_trigger_put" {
  statement_id  = "AllowExecutionFromAPIGatewayPUT"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:${aws_api_gateway_rest_api.api.id}/*/PUT/*"
}
