#locals {
#  bucket_name = "dfds-backup-reports"
#}
#
#module "reports_bucket" {
#  source = "git::https://github.com/dfds/aws-modules-s3.git?ref=v1.3.0"
#
#  bucket_name                     = local.bucket_name
#  bucket_versioning_configuration = "Enabled"
#  object_ownership                = "BucketOwnerPreferred"
#  create_policy                   = true
#  create_logging_bucket           = true
#  logging_bucket_name             = "${local.bucket_name}-s3-logs"
#  source_policy_documents         = [data.aws_iam_policy_document.bucket.json]
#}
#
#data "aws_iam_role" "backup_service_role" {
#  name = "AWSServiceRoleForBackupReports"
#}
#
#data "aws_iam_policy_document" "bucket" {
#  statement {
#    sid    = "AllowPutObject"
#    effect = "Allow"
#    principals {
#      identifiers = [data.aws_iam_role.backup_service_role.arn]
#      type        = "AWS"
#    }
#    actions   = ["s3:PutObject"]
#    resources = ["arn:aws:s3:::${local.bucket_name}/*"]
#    condition {
#      test     = "StringEquals"
#      values   = ["bucket-owner-full-control"]
#      variable = "s3:x-amz-acl"
#    }
#  }
#}
