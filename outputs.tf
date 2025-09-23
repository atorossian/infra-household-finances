output "s3_bucket_name" {
  value = aws_s3_bucket.data.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.api.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.api.name
}

output "execution_role_arn" {
  value = aws_iam_role.ecs_execution.arn
}

output "task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "github_actions_app_role_arn" {
  value = aws_iam_role.github_actions_app.arn
}

output "github_actions_infra_role_arn" {
  value = aws_iam_role.github_actions_infra.arn
}

output "secret_name" {
  value = aws_secretsmanager_secret.app.name
}
