provider "aws" {
  region = var.aws_region

  # No assume_role and no allowed_account_ids here.
  # Auth comes from your shell/CI (already-assumed role or env vars).
  default_tags {
    tags = {
      Project     = "household-finances"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
