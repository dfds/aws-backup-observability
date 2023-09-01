provider "aws" {
  region = "eu-central-1"
  assume_role {
    role_arn = var.aws_assume_role_arn
  }
  default_tags {
    tags = var.default_tags
  }
}