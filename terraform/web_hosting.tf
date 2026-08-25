#**********************
# Web Hosting (via reusable module)
# S3 + CloudFront + ACM + Route53 for clt.dynasty.xomware.com
#**********************

module "web" {
  source = "git::https://github.com/domgiordano/web-hosting.git?ref=v1.1.0"

  app_name    = var.app_name
  domain_name = local.domain_name
  zone_id     = data.aws_route53_zone.web_zone.zone_id
  tags        = local.standard_tags

  # S3 — no CMK.
  #
  # This bucket holds a compiled Angular app that CloudFront serves to the
  # public internet. Encrypting public files with a customer-managed key buys
  # no confidentiality; it costs $1/month for the key plus a KMS request on
  # object reads, and it forces the dependency cycle documented in kms.tf.
  #
  # Empty string makes the module fall back to SSE-S3 (AES256): still
  # encrypted at rest, AWS-managed, free.
  kms_key_arn = ""

  # CloudFront
  waf_acl_arn               = data.aws_ssm_parameter.shared_cloudfront_waf_arn.value
  spa_error_path            = var.custom_error_response_page_path
  geo_restriction_locations = var.us_canada_only ? ["US", "CA"] : []
  enable_cache              = var.enable_cloudfront_cache
  origin_path               = var.cloudfront_origin_path
  minimum_tls_version       = var.minimum_tls_version
  retain_on_delete          = var.retain_on_delete
}
