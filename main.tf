# S3 Bucket
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

# ECR Repository
resource "aws_ecr_repository" "api" {
  name = var.app_name
}

# ECS Cluster
resource "aws_ecs_cluster" "api" {
  name = "${var.app_name}-${var.env}-cluster"
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.app_name}-${var.env}"
  retention_in_days = 30
}

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

# Inline policy for S3 bucket access
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

resource "aws_iam_role" "github_actions" {
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
          "token.actions.githubusercontent.com:sub" = "repo:atorossian/infra-household-finances:environment:${var.env}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions_policy" {
  name = "${var.app_name}-${var.env}-github-actions-policy"
  role = aws_iam_role.github_actions.id

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

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "app" {
  name        = "${var.app_name}/${var.env}/app"
  description = "App secrets for ${var.env} environment of ${var.app_name}"
}