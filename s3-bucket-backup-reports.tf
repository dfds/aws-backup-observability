locals {
  bucket_name = "dfds-backup-reports"
  lifecycle_configuration = [
    {
      id     = "delete-after-90-days"
      status = "Enabled"
      expiration = {
        days = 90
      }
      noncurrent_version_expiration = {
        noncurrent_days = 90
      }
    }
  ]
}

module "reports_bucket" {
  source = "git::https://github.com/dfds/aws-modules-s3.git?ref=v1.4.1"

  bucket_name                     = local.bucket_name
  bucket_versioning_configuration = "Enabled"
  object_ownership                = "BucketOwnerPreferred"
  create_policy                   = true
  create_logging_bucket           = true
  logging_bucket_name             = "${local.bucket_name}-s3-logs"
  source_policy_documents         = [data.aws_iam_policy_document.bucket.json]
  lifecycle_rules                 = local.lifecycle_configuration
  logging_bucket_lifecycle_rules  = local.lifecycle_configuration
}

resource "aws_iam_service_linked_role" "backup" {
  aws_service_name = "reports.backup.amazonaws.com"
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid    = "AllowPutObject"
    effect = "Allow"
    principals {
      identifiers = [aws_iam_service_linked_role.backup.arn]
      type        = "AWS"
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]
    condition {
      test     = "StringEquals"
      values   = ["bucket-owner-full-control"]
      variable = "s3:x-amz-acl"
    }
  }
}
