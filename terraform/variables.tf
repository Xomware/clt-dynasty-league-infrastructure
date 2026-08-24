variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Short app identifier. Used for tags and the KMS alias."
  type        = string
  default     = "clt-dynasty"
}

variable "domain_name" {
  description = "Fully qualified domain the site is served from."
  type        = string
  default     = "clt.dynasty.xomware.com"
}

variable "route53_zone_name" {
  description = "Shared Xomware hosted zone."
  type        = string
  default     = "xomware.com"
}

variable "environment" {
  description = "Deployment environment tag."
  type        = string
  default     = "production"
}

variable "owner" {
  description = "Owner tag."
  type        = string
  default     = "domgiordano"
}

variable "custom_error_response_page_path" {
  description = "SPA fallback path. Angular handles routing client-side."
  type        = string
  default     = "/index.html"
}

variable "us_canada_only" {
  description = "Restrict CloudFront viewers to US and CA."
  type        = bool
  default     = true
}

variable "enable_cloudfront_cache" {
  description = "CloudFront caching. On, with the module's 60s default/max TTL."
  type        = bool
  default     = true
}

variable "cloudfront_origin_path" {
  description = "Origin path prefix. Empty means the bucket root is the site root."
  type        = string
  default     = ""
}

variable "minimum_tls_version" {
  description = "Minimum viewer TLS version."
  type        = string
  default     = "TLSv1.2_2018"
}

variable "retain_on_delete" {
  description = "Retain the CloudFront distribution on destroy."
  type        = bool
  default     = false
}
