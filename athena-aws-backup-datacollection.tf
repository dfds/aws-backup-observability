locals {
  athena_workgroup_name  = var.project_name
  bucket_query_results   = "${aws_s3_bucket.reporting.bucket}/athena"
  athena_output_location = "${aws_s3_bucket.reporting.bucket}/athena/output"
  source_bucket_path     = "${aws_s3_bucket.reporting.bucket}/data"
  athena_table_name      = "${var.project_name}_service_metrics"
  aws_iam_role           = "${var.project_name}_athena_access"
}

resource "aws_s3_bucket" "reporting" {
  bucket        = var.bucket_name
  force_destroy = var.bucket_force_delete

  #   lifecycle {
  #     prevent_destroy = true
  #   }
}

resource "aws_athena_workgroup" "reporting" {
  name          = local.athena_workgroup_name
  force_destroy = true

  configuration {
    result_configuration {
      output_location = "s3://${local.athena_output_location}"
    }
  }
}

resource "aws_athena_database" "reporting" {
  name          = var.athena_db_name
  bucket        = local.bucket_query_results
  force_destroy = true
}

resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = local.athena_table_name
  database_name = aws_athena_database.reporting.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL                 = "TRUE"
    "skip.header.line.count" = "1"
  }

  storage_descriptor {
    location      = "s3://${local.source_bucket_path}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "my-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim" = ","
      }
    }
    columns {
      name = "report_time_period_start"
      type = "string"
    }
    columns {
      name = "report_time_period_end"
      type = "string"
    }
    columns {
      name = "path_to_root"
      type = "string"
    }
    columns {
      name = "account_id"
      type = "string"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "backup_job_id"
      type = "string"
    }
    columns {
      name = "job_status"
      type = "string"
    }
    columns {
      name = "status_message"
      type = "string"
    }
    columns {
      name = "resource_type"
      type = "string"
    }
    columns {
      name = "resource_arn"
      type = "string"
    }
    columns {
      name = "backup_plan_arn"
      type = "string"
    }
    columns {
      name = "backup_rule_id"
      type = "string"
    }
    columns {
      name = "creation_date"
      type = "string"
    }
    columns {
      name = "completion_date"
      type = "string"
    }
    columns {
      name = "expected_completion_date"
      type = "string"
    }
    columns {
      name = "recovery_point_arn"
      type = "string"
    }
    columns {
      name = "job_run_time"
      type = "string"
    }
    columns {
      name = "backup_size_in_bytes"
      type = "int"
    }
    columns {
      name = "backup_vault_name"
      type = "string"
    }
    columns {
      name = "backup_vault_arn"
      type = "string"
    }
    columns {
      name = "iam_role_arn"
      type = "string"
    }
  }
}



data "aws_iam_policy_document" "this" {
  statement {
    sid       = "AthenaQueryAccess"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "athena:ListDatabases",
      "athena:ListDataCatalogs",
      "athena:ListWorkGroups",
      "athena:GetDatabase",
      "athena:GetDataCatalog",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetTableMetadata",
      "athena:GetWorkGroup",
      "athena:ListTableMetadata",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution",
    ]
  }

  statement {
    sid       = "GlueReadAccess"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:BatchGetPartition",
    ]
  }

  statement {
    sid       = "AthenaS3Access"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.bucket_name}/*", "arn:aws:s3:::${var.bucket_name}"]

    actions = [
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
      "s3:PutObject",
    ]
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.project_name}_grafana_athena"
  description = "Allows API access AWS Athena"
  policy      = data.aws_iam_policy_document.this.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = var.oidc_endpoint_kubernetes
    }
    condition {

      test     = "StringEquals"
      variable = var.oidc_eks_for_athena
      values   = ["system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.project_name}_grafana_athena"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}


data "aws_iam_policy_document" "grafana_cloud" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = var.grafana_stack_ids
    }

    principals {
      type        = "AWS"
      identifiers = var.grafana_cloud_arn
    }
  }
}

resource "aws_iam_role" "grafana" {
  name               = "${var.project_name}_grafana_cloud_athena"
  assume_role_policy = data.aws_iam_policy_document.grafana_cloud.json
}

resource "aws_iam_role_policy_attachment" "grafana_cloud" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.this.arn
}
