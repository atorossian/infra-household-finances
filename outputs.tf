output "gha_infra_role_arn" {
  value       = module.gha_oidc.roles["infra"].role_arn
  description = "Role ARN that infra repo uses to run terraform in dev"
}

output "gha_app_role_arn" {
  value       = module.gha_oidc.roles["app"].role_arn
  description = "Role ARN that app repo uses to push to ECR (and later deploy ECS)"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "ECR repo URL to push images to"
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "alb_dns_name" {
  value       = try(one(module.ecs_alb[*].alb_dns_name), null)
  description = "ALB DNS name (null when enable_ecs_alb=false)"
}

output "ecs_cluster_name" {
  value       = try(one(module.ecs_alb[*].cluster_name), null)
  description = "ECS cluster name (null when enable_ecs_alb=false)"
}

output "ecs_service_name" {
  value       = try(one(module.ecs_alb[*].service_name), null)
  description = "ECS service name (null when enable_ecs_alb=false)"
}
output "apprunner_service_url" {
  value       = try(module.apprunner[0].service_url, null)
  description = "Public HTTPS URL for App Runner"
}

output "apprunner_service_arn" {
  value       = try(module.apprunner[0].service_arn, null)
  description = "App Runner service ARN"
}