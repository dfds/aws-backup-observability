data "aws_organizations_organization" "this" {}

resource "aws_backup_report_plan" "this" {
  name        = "backup_jobs_organization_report"
  description = "Report plan to aggregate results of backup jobs across the organization"
  report_delivery_channel {
    s3_bucket_name = module.reports_bucket.bucket_name
    formats        = ["CSV"]
  }
  report_setting {
    report_template = "BACKUP_JOB_REPORT"
    accounts        = [for account in data.aws_organizations_organization.this.non_master_accounts : account.id]
    regions = [
      "eu-central-1",
      "eu-west-1"
    ]
  }
}
