#locals {
#  lambda_name = "backup-reporter"
#}
#
#resource "aws_lambda_function" "lambda" {
#  function_name                  = local.lambda_name
#  role                           = aws_iam_role.lambda.arn
#  timeout                        = 120
#  memory_size                    = 512
#  reserved_concurrent_executions = "-1"
#  runtime                        = "python3.10"
#  handler                        = "main.handler"
#  s3_bucket                      = "dfds-ce-shared-artifacts"
#  s3_key                         = "aws-backup-observability/${local.lambda_name}-lambda.zip"
#  source_code_hash               = data.aws_s3_object.lambda.etag
#
#  environment {
#    variables = {
#      SLACK_WEBHOOK = var.slack_webhook_url
#    }
#  }
#
#  tracing_config {
#    mode = "Active"
#  }
#}
#
#data "aws_s3_object" "lambda" {
#  bucket = "dfds-ce-shared-artifacts"
#  key    = "aws-backup-observability/${local.lambda_name}-lambda.zip"
#}
#
#resource "aws_iam_role" "lambda" {
#  name               = local.lambda_name
#  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
#}
#
#data "aws_iam_policy_document" "lambda_trust" {
#  statement {
#    actions = ["sts:AssumeRole"]
#    principals {
#      identifiers = ["lambda.amazonaws.com"]
#      type        = "Service"
#    }
#  }
#}
#
#resource "aws_iam_role_policy_attachment" "lambda" {
#  policy_arn = aws_iam_policy.lambda_access.arn
#  role       = aws_iam_role.lambda.name
#}
#
#resource "aws_iam_policy" "lambda_access" {
#  name        = "${local.lambda_name}-lambda-access"
#  description = "Access policy for the ${local.lambda_name} lambda"
#  policy      = data.aws_iam_policy_document.lambda_access.json
#}
#
#data "aws_iam_policy_document" "lambda_access" {
#  statement {
#    sid = "ClowudwatchAccess"
#    actions = [
#      "logs:CreateLogStream",
#      "logs:PutLogEvents"
#    ]
#    resources = [
#      "${aws_cloudwatch_log_group.lambda.arn}:*"
#    ]
#  }
#  statement {
#    sid       = "AllowGetObject"
#    actions   = ["s3:GetObject"]
#    resources = ["${module.reports_bucket.bucket_arn}/*"]
#  }
#}
#
#resource "aws_cloudwatch_log_group" "lambda" {
#  name              = "/aws/lambda/${local.lambda_name}"
#  retention_in_days = 0
#}
#
#resource "aws_lambda_permission" "this" {
#  statement_id  = "AllowExecutionFromS3Bucket"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.lambda.function_name
#  principal     = "s3.amazonaws.com"
#  source_arn    = module.reports_bucket.bucket_arn
#}
#
#resource "aws_s3_bucket_notification" "this" {
#  bucket = module.reports_bucket.bucket_name
#
#  lambda_function {
#    lambda_function_arn = aws_lambda_function.lambda.arn
#    events              = ["s3:ObjectCreated:*"]
#    filter_prefix       = "Backup/"
#    filter_suffix       = ".csv"
#  }
#
#  depends_on = [aws_lambda_permission.this]
#}
