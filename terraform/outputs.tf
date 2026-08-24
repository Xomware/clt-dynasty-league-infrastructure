# Output names match the set already recorded in state. Renaming any of these
# shows up as output churn on every plan for no benefit.

output "s3_bucket_id" {
  description = "S3 bucket the frontend deploy syncs to."
  value       = module.web.s3_bucket_id
}

output "s3_bucket_arn" {
  value = module.web.s3_bucket_arn
}

output "cloudfront_distribution_id" {
  description = "Distribution to invalidate after a deploy."
  value       = module.web.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  value = module.web.cloudfront_domain_name
}

output "certificate_arn" {
  value = module.web.certificate_arn
}

output "domain_name" {
  value = local.domain_name
}

output "kms_key_arn" {
  value = aws_kms_key.web_app.arn
}
