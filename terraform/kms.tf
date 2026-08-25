# DEPRECATED — retained deliberately, do not delete yet.
#
# The site bucket no longer encrypts NEW objects with this key; it uses SSE-S3
# (see web_hosting.tf). But every object written before that change is still
# encrypted with this CMK, and an S3 object encrypted with a deleted key is
# unrecoverable. Deleting this now would take the site down.
#
# Removal sequence:
#   1. This change lands. New uploads are AES256.
#   2. Redeploy the frontend. `aws s3 sync --delete` rewrites every object,
#      so the whole bucket becomes AES256.
#   3. Confirm nothing is left on the old key:
#        aws s3api list-objects-v2 --bucket clt.dynasty.xomware.com \
#          --query 'Contents[].Key' --output text | while read k; do
#            aws s3api head-object --bucket clt.dynasty.xomware.com --key "$k" \
#              --query 'ServerSideEncryption' --output text; done | sort -u
#      Expect AES256 only.
#   4. Only then delete these three resources. Saves ~$1/month.
#
# Worth doing across the estate: 15 customer-managed keys exist and KMS billed
# $10.51 in August, most of it encrypting publicly-served website assets.

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
