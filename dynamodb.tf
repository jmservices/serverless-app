resource "aws_dynamodb_table" "db" {
  name           = lower(format("%s_db", var.project_name))
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "username"

  attribute {
    name = "username"
    type = "S"
  }

  tags = local.tags
}
