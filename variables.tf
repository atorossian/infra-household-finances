variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile name"
}

variable "env" {
  type        = string
  description = "Environment name (dev/staging/prod)"
}

variable "app_name" {
  type        = string
  description = "Base app name"
  default     = "household-finances"
}
