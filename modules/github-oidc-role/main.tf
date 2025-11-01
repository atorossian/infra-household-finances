locals {
  github_thumbprints = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  app_sub   = "repo:${var.github_owner}/${var.app_repo_name}:ref:refs/heads/${var.main_branch}"
  infra_sub = "repo:${var.github_owner}/${var.infra_repo_name}:ref:refs/heads/${var.main_branch}"
}

# Create OIDC provider only if requested (set create_oidc_provider=false if it already exists in the account)
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = local.github_thumbprints
}

# Helper to get the provider ARN regardless of whether we created it or not.
# If you set create_oidc_provider=false, set this variable via tfvar/ENV to the
# existing provider ARN; otherwise we use the resource we just created.
variable "existing_github_oidc_provider_arn" {
  description = "If create_oidc_provider=false, specify the existing OIDC provider ARN."
  type        = string
  default     = ""
}

# --- OIDC ARN resolution (safe for count=0) ---
locals {
  # If the resource was created, this is a single ARN; if not, it's null.
  created_oidc_arn = try(one(aws_iam_openid_connect_provider.github[*].arn), null)

  # Prefer created ARN, otherwise use provided existing ARN; otherwise null.
  oidc_provider_arn = coalesce(
    local.created_oidc_arn,
    length(trimspace(var.existing_github_oidc_provider_arn)) > 0 ? var.existing_github_oidc_provider_arn : null
  )
}

# Fail fast if user forgot to pass the existing ARN when skipping creation
resource "null_resource" "assert_oidc_arn" {
  triggers = {
    oidc = tostring(local.oidc_provider_arn)
  }

  lifecycle {
    precondition {
      condition     = local.oidc_provider_arn != null
      error_message = "No GitHub OIDC provider ARN available. Set create_oidc_provider=true or pass existing_github_oidc_provider_arn."
    }
  }
}

data "aws_iam_policy_document" "assume_role_app" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.app_sub]
    }
  }
}

data "aws_iam_policy_document" "assume_role_infra" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.infra_sub]
    }
  }
}

resource "aws_iam_role" "gha_infra" {
  name               = "gha-infra-${var.infra_repo_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_infra.json
  description        = "Assumed by GitHub Actions (${var.github_owner}/${var.infra_repo_name}) to run Terraform"
}

resource "aws_iam_role" "gha_app" {
  name               = "gha-app-${var.app_repo_name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_app.json
  description        = "Assumed by GitHub Actions (${var.github_owner}/${var.app_repo_name}) to build/push image to ECR (and later deploy)"
}

data "aws_iam_policy_document" "app_ecr_policy" {
  statement {
    sid     = "ECRAuth"
    effect  = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid     = "ECRPushPull"
    effect  = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "app_ecr_policy" {
  name        = "gha-app-ecr-push"
  description = "Allow pushing/pulling images to ECR (app)"
  policy      = data.aws_iam_policy_document.app_ecr_policy.json
}

resource "aws_iam_role_policy_attachment" "gha_app_attach_ecr" {
  role       = aws_iam_role.gha_app.name
  policy_arn = aws_iam_policy.app_ecr_policy.arn
}

resource "aws_iam_role_policy_attachment" "infra_admin" {
  count      = var.attach_admin_policy_to_infra ? 1 : 0
  role       = aws_iam_role.gha_infra.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "roles" {
  value = {
    infra = {
      role_name = aws_iam_role.gha_infra.name
      role_arn  = aws_iam_role.gha_infra.arn
    }
    app = {
      role_name = aws_iam_role.gha_app.name
      role_arn  = aws_iam_role.gha_app.arn
    }
  }
}
