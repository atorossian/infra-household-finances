############################################
# Data sources
############################################

data "aws_caller_identity" "current" {}

############################################
# S3 bucket (per env)
############################################

resource "aws_s3_bucket" "data" {
  bucket = "${var.app_name}-${var.env}"
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

############################################
# ECR repository (shared name, per account)
############################################

resource "aws_ecr_repository" "api" {
  name = var.app_name
}

############################################
# ECS cluster
############################################

resource "aws_ecs_cluster" "api" {
  name = "${var.app_name}-${var.env}-cluster"
}

############################################
# CloudWatch log group
############################################

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.app_name}-${var.env}"
  retention_in_days = 30
}

############################################
# IAM roles
############################################

# Execution role (used by ECS agent)
resource "aws_iam_role" "ecs_execution" {
  name = "${var.app_name}-${var.env}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role (used by your app container)
resource "aws_iam_role" "ecs_task" {
  name = "${var.app_name}-${var.env}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Inline policy for S3 access
resource "aws_iam_role_policy" "ecs_task_s3" {
  name = "${var.app_name}-${var.env}-s3-access"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${aws_s3_bucket.data.id}"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${aws_s3_bucket.data.id}/*"
      }
    ]
  })
}

############################################
# GitHub OIDC roles
############################################

# App repo OIDC role (for deployments)
resource "aws_iam_role" "github_actions_app" {
  name = "${var.app_name}-${var.env}-github-actions-ecs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # 👇 Replace with your real GitHub org/user + repo name
          "token.actions.githubusercontent.com:sub" = "repo:atorossian/household-finances:environment:${var.env}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions_app_policy" {
  name = "${var.app_name}-${var.env}-github-actions-ecs-policy"
  role = aws_iam_role.github_actions_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:*",
          "ecs:Describe*",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "iam:PassRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# Infra repo OIDC role (for Terraform applies)
resource "aws_iam_role" "github_actions_infra" {
  name = "${var.app_name}-${var.env}-github-actions-infra"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # 👇 Replace with your real GitHub org/user + repo name
          "token.actions.githubusercontent.com:sub" = "repo:atorossian/infra-household-finances:environment:${var.env}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions_infra_policy" {
  name = "${var.app_name}-${var.env}-github-actions-infra-policy"
  role = aws_iam_role.github_actions_infra.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "ecr:*",
          "ecs:*",
          "iam:*",
          "logs:*",
          "secretsmanager:*"
        ]
        Resource = "*"
      }
    ]
  })
}

############################################
# Secrets Manager container
############################################

resource "aws_secretsmanager_secret" "app" {
  name        = "${var.app_name}/${var.env}/app"
  description = "App secrets container for ${var.env} environment"
}
