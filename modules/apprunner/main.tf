# modules/apprunner/main.tf

# Role App Runner uses to pull from ECR (private repos)
data "aws_iam_policy_document" "apprunner_access_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = [
        "build.apprunner.amazonaws.com",
        "tasks.apprunner.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "apprunner_access" {
  name               = "${var.service_name}-access-role"
  assume_role_policy = data.aws_iam_policy_document.apprunner_access_trust.json
}

# Allow pulling images from ECR (read-only)
data "aws_iam_policy_document" "ecr_pull" {
  statement {
    sid     = "ECRAuth"
    effect  = "Allow"
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid     = "ECRPull"
    effect  = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_pull" {
  name   = "${var.service_name}-ecr-pull"
  policy = data.aws_iam_policy_document.ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "attach_ecr_pull" {
  role       = aws_iam_role.apprunner_access.name
  policy_arn = aws_iam_policy.ecr_pull.arn
}

# Optional: minimal auto scaling config (keeps 1 warm instance)
resource "aws_apprunner_auto_scaling_configuration_version" "basic" {
  auto_scaling_configuration_name = "${var.service_name}-asc"
  max_concurrency                 = 100
  max_size                        = 2
  min_size                        = 1
}

resource "aws_apprunner_service" "this" {
  service_name = var.service_name

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_access.arn
    }

    image_repository {
      image_identifier      = var.image_url   # repo:tag
      image_repository_type = "ECR"

      
    image_configuration {
      port = tostring(var.port)
      runtime_environment_variables = merge(var.env_vars, { PORT = tostring(var.port) })
      # optional:
      # start_command = var.start_command == "" ? null : var.start_command
    }

    }

    auto_deployments_enabled = var.auto_deploy
  }

  # Ignore image tag drift so pushing the same tag can trigger deploys
  lifecycle {
    ignore_changes = [source_configuration[0].image_repository[0].image_identifier]
  }

  instance_configuration {
    cpu    = var.cpu
    memory = var.memory
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = var.health_path
    healthy_threshold   = 1
    unhealthy_threshold = 5
    interval            = 10
    timeout             = 5
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.basic.arn

  tags = {
    Project     = "household-finances"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
