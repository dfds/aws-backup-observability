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

variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "bucket_force_delete" {
  type    = bool
  default = false
}


variable "k8s_namespace" {
  type = string
}

variable "k8s_service_account" {
  type = string
}

variable "oidc_endpoint_kubernetes" {
  type        = list(string)
  description = "The OIDC endpoint ARN for the EKS cluster"
}

variable "oidc_eks_for_athena" {
  type        = string
  description = "The OIDC endpoint that Athena will be using"
}

variable "grafana_stack_ids" {
  type        = list(string)
  description = "This is a list of Grafana stack IDs that are allowed to assume the role"
}

variable "grafana_cloud_arn" {
  type        = list(string)
  description = "The ARN of Grafana Cloud connection."
}

variable "athena_db_name" {
  type        = string
  description = "The name of the Athena database which is created by AWS Glue"
}