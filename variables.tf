variable "aws_assume_role_arn" {
  type        = string
  description = "ARN of the role to assume by the provider"
  default     = ""
}

variable "default_tags" {
  type        = object({})
  description = "A map of default tags that will be applied to all resources that support tagging"
  default     = {}
}

variable "slack_webhook_url" {
  type        = string
  description = "Slack webhook URL used to post backup reports"
  sensitive   = true
}
