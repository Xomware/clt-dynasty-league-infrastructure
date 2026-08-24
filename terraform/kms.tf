# CMK for the site bucket.
#
# The key policy is a SEPARATE aws_kms_key_policy resource rather than an
# inline `policy` argument on the key, which is how xomper-infrastructure
# does it. Inlining it here creates a dependency cycle:
#
#   key policy -> CloudFront distribution ARN -> KMS alias -> key
#
# A from-empty `terraform apply` cannot resolve that cycle. Splitting the
# policy into its own resource breaks it. Do not inline this.

resource "aws_kms_key" "web_app" {
  description         = "KMS CMK for CLT Dynasty web app S3 bucket"
  enable_key_rotation = true

  tags = merge(local.standard_tags, {
    "description" = "KMS CMK for web app S3 bucket"
  })
}

resource "aws_kms_alias" "web_app" {
  name          = "alias/${var.app_name}-web-app"
  target_key_id = aws_kms_key.web_app.key_id
}

resource "aws_kms_key_policy" "web_app" {
  key_id = aws_kms_key.web_app.id

  policy = jsonencode({
    "Id" : "KMSKeyPolicy",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Full key access for account root",
        "Effect" : "Allow",
        "Principal" : { "AWS" : ["arn:aws:iam::${local.web_app_account_id}:root"] },
        "Action" : ["kms:*"],
        "Resource" : "*"
      },
      {
        "Sid" : "Key access for account roles via S3",
        "Effect" : "Allow",
        "Principal" : { "AWS" : ["arn:aws:iam::${local.web_app_account_id}:root"] },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "kms:CallerAccount" : local.web_app_account_id,
            "kms:ViaService"    : "s3.${var.aws_region}.amazonaws.com"
          }
        }
      },
      {
        "Sid" : "CloudFront key access",
        "Effect" : "Allow",
        "Principal" : { "Service" : ["cloudfront.amazonaws.com"] },
        "Action" : ["kms:Decrypt"],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:SourceArn" : module.web.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}
