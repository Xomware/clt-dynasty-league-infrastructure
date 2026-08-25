# DEPRECATED — retained deliberately, do not delete yet.
#
# The site bucket no longer encrypts NEW objects with this key; it uses SSE-S3
# (see web_hosting.tf). But objects encrypted with this CMK are unrecoverable
# once it is deleted, so removing it too early takes the site down or destroys
# the ability to roll back.
#
# THE VERSIONING TRAP. This bucket is versioned. After the switch to AES256
# and a redeploy, all 56 CURRENT objects were AES256 — but 591 versions
# existed, and the noncurrent ones were still aws:kms. A check based on
# `list-objects-v2` only sees current objects and would have passed with ~535
# KMS-encrypted versions still present. Deleting the key at that point would
# have silently destroyed every rollback target.
#
# Removal sequence:
#   1. Bucket switched to AES256 (done).
#   2. Redeploy so current objects are rewritten (done).
#   3. Wait for noncurrent versions to age out. The module's lifecycle rule
#      keeps the latest 3 versions, so roughly three more deploys clears them.
#   4. Verify across ALL VERSIONS, not just current objects:
#        aws s3api list-object-versions --bucket clt.dynasty.xomware.com \
#          --query 'Versions[].[Key,VersionId]' --output text |
#        while read k v; do
#          aws s3api head-object --bucket clt.dynasty.xomware.com \
#            --key "$k" --version-id "$v" \
#            --query 'ServerSideEncryption' --output text
#        done | sort -u
#      Expect AES256 only. If aws:kms appears, the key is still load-bearing.
#   5. Only then delete these three resources. Saves ~$1/month.
#
# Worth doing across the estate: 15 customer-managed keys exist and KMS billed
# $10.51 in August, most of it encrypting publicly-served website assets. Each
# one needs this same sequence, versioning trap included.

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
