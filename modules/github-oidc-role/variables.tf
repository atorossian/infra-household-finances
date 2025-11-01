variable "github_owner"    { type = string }
variable "app_repo_name"   { type = string }
variable "infra_repo_name" { type = string }
variable "main_branch"     { type = string }

variable "attach_admin_policy_to_infra" {
  description = "If true, attach AdministratorAccess to infra role (DEV only)."
  type        = bool
  default     = true
}

variable "create_oidc_provider" {
  description = "Actually create the GitHub OIDC provider resource"
  type        = bool
  default     = true
}

