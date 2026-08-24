# Shared xomware.com hosted zone. The site's A record and the ACM validation
# CNAME are both created inside the web-hosting module, not here.

data "aws_route53_zone" "web_zone" {
  name         = var.route53_zone_name
  private_zone = false
}

# Shared CloudFront WAF ACL, exported by xomware-infrastructure.
data "aws_ssm_parameter" "shared_cloudfront_waf_arn" {
  name = "/xomware/shared/cloudfront-waf-acl-arn"
}
