locals {
  domain_name = var.domain_name

  web_app_account_id = data.aws_caller_identity.web_app_account.account_id

  standard_tags = {
    "source"      = "terraform"
    "app_name"    = var.app_name
    "environment" = var.environment
    "owner"       = var.owner
  }
}
