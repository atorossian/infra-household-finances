variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Env name"
  type        = string
  default     = "dev"
}

variable "github_owner" {
  description = "GitHub org/user that owns the repos"
  type        = string
  # TODO: set this to your real GitHub username/org
  default     = "atorossian"
}

variable "app_repo_name" {
  description = "App repo (build & push image)"
  type        = string
  default     = "household-finances"
}

variable "infra_repo_name" {
  description = "Infra repo (runs terraform)"
  type        = string
  default     = "infra-household-finances"
}

variable "main_branch" {
  description = "Default branch"
  type        = string
  default     = "main"
}

variable "ecr_repo_name" {
  description = "ECR repo to store the app image"
  type        = string
  default     = "household-finances"
}

variable "dev_account_id" {
  description = "hf-dev account ID"
  type        = string
  default     = "378779692580"
}

variable "create_oidc_provider" {
  description = "Create GitHub OIDC provider in this account. Set to false if one already exists."
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "VPC CIDR for dev"
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "How many AZs to span"
  type        = number
  default     = 2
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "hf-dev"
}

variable "container_port" {
  description = "Container/app port exposed by your service"
  type        = number
  default     = 8000
}

variable "desired_count" {
  description = "ECS desired task count"
  type        = number
  default     = 1
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory (MiB)"
  type        = number
  default     = 1024
}

variable "health_check_path" {
  description = "ALB health check path"
  type        = string
  default     = "/health"
}

variable "image_tag" {
  description = "Image tag to deploy from ECR"
  type        = string
  default     = "latest"
}

variable "create_nat_gateway" {
  description = "Create a NAT Gateway (fixed cost). For personal/dev, set false."
  type        = bool
  default     = false
}

variable "enable_ecs_alb" {
  description = "Deploy ECS + ALB stack"
  type        = bool
  default     = false
}

# App Runner common
variable "enable_apprunner" {
  description = "Create App Runner service"
  type        = bool
  default     = true
}

variable "apprunner_service_name" {
  description = "Service name (unique per account)"
  type        = string
  default     = "hf-dev-apprunner"
}

variable "apprunner_image_url" {
  description = "ECR image URI (repo:tag), e.g. 123456789012.dkr.ecr.eu-west-1.amazonaws.com/household-finances:dev"
  type        = string
}

variable "apprunner_port" {
  description = "Container port"
  type        = number
  default     = 8000
}

variable "apprunner_cpu" {
  description = "Instance CPU: one of '0.25 vCPU','0.5 vCPU','1 vCPU','2 vCPU','4 vCPU'"
  type        = string
  default     = "0.25 vCPU"
}

variable "apprunner_memory" {
  description = "Instance Memory: '512 MB','1 GB','2 GB','3 GB','4 GB','8 GB','16 GB','32 GB'"
  type        = string
  default     = "512 MB"
}

variable "apprunner_health_path" {
  description = "Health check path"
  type        = string
  default     = "/health"
}

variable "apprunner_auto_deploy" {
  description = "Auto-deploy on new image push to the same tag"
  type        = bool
  default     = true
}

# Optional env vars you want App Runner to inject into the container
variable "apprunner_env_vars" {
  description = "Map of plain environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "app_env" {
  description = "Environment name (e.g. dev, staging, pr-123)"
  type        = string
}

# If you have an app bucket, make it unique per env:
variable "app_bucket_prefix" {
  description = "Base S3 bucket prefix (globally unique-ish prefix)"
  type        = string
  default     = "hf-app"
}