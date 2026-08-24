# clt-dynasty-league-infrastructure

Terraform for **clt.dynasty.xomware.com** — the CLT Dynasty League app
(`clt-dynasty-league-frontend`).

## What this manages

S3 + CloudFront + ACM + Route53 static site hosting, plus the KMS CMK that
encrypts the bucket. Hosting comes from the shared
[`web-hosting`](https://github.com/domgiordano/web-hosting) module, the same
one `xomforms-infrastructure` uses.

| Resource | Value |
|---|---|
| Domain | `clt.dynasty.xomware.com` |
| Bucket | `clt.dynasty.xomware.com` |
| CloudFront | `E2C3YYJUEV78O7` |
| KMS alias | `alias/clt-dynasty-web-app` |
| State | `s3://xomware-terraform-state/clt-dynasty-league/terraform.tfstate` |
| Lock table | `xomware-terraform-locks` |

## How this repo came to exist

The AWS resources were applied on 2026-08-24 from a working directory that was
never committed. State landed in S3; the source did not land anywhere. A code
search across the Xomware org found no Terraform for any of it — live
infrastructure with remote state and no version-controlled source.

This repo is that source, **reconstructed from the state file** and verified
by a `terraform plan` showing no changes. If you are reading this while
wondering whether the config matches reality: that is what the plan in CI is
for. It runs on every PR.

## Deploys

`terraform.yml` follows the house pattern: plan on PR (posted as a comment),
apply on push to `master`. Self-hosted — no Terraform Cloud.

Requires repo secrets `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

## Local

```bash
cd terraform
terraform init
terraform plan
```

## Gotcha: the KMS key policy is a separate resource

`aws_kms_key_policy.web_app` is deliberately split out from `aws_kms_key`
rather than inlined as a `policy` argument. Inlining creates a dependency
cycle — key policy needs the CloudFront ARN, CloudFront needs the KMS alias,
the alias needs the key — which makes a from-empty apply impossible. Leave it
split.
