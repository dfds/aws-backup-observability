variable "default_tags" {
  type = object({})
  description = "A map of default tags that will be applied to all resources that support tagging"
  default = {}
}

variable "slack_webhook_url" {
  type        = string
  description = "Slack webhook URL used to post backup reports"
  sensitive   = true
}
