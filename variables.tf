variable "project_name" {
  description = "Project name."

  default = "Birthday"
  type    = string
}

variable "project_category" {
  description = "Project category."

  default = "api"
  type    = string
}

variable "environment" {
  description = "Project environment."

  default = "test"
  type    = string
}

locals {
  tags = {
    "project"     = var.project_name,
    "category"    = var.project_category,
    "environment" = var.environment
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
