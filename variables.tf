variable "slack_webhook_url" {
  type = string
  description = "Slack webhook URL used to post backup reports"
  sensitive = true
}