locals {
  env         = var.app_env
  name_prefix = "hf-${local.env}" # e.g. hf-pr-123
  tags = {
    Project     = "household-finances"
    Environment = local.env
    ManagedBy   = "terraform"
  }
}
