module "gha_oidc" {
  source          = "./modules/github-oidc-role"

  github_owner    = var.github_owner
  app_repo_name   = var.app_repo_name
  infra_repo_name = var.infra_repo_name
  main_branch     = var.main_branch

  attach_admin_policy_to_infra = true
  create_oidc_provider = var.create_oidc_provider 
}


module "ecr" {
  source         = "./modules/ecr-repo"
  repository_name = var.ecr_repo_name
}

module "network" {
  source              = "./modules/network"
  name_prefix         = var.name_prefix
  vpc_cidr            = var.vpc_cidr
  az_count            = var.az_count
  single_nat_gateway  = true
  create_nat_gateway  = var.create_nat_gateway
}


module "ecs_alb" {
  count = var.enable_ecs_alb ? 1 : 0
  source = "./modules/ecs-alb"

  name_prefix        = var.name_prefix
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids

  container_port    = var.container_port
  desired_count     = var.desired_count
  task_cpu          = var.task_cpu
  task_memory       = var.task_memory
  health_check_path = var.health_check_path
  image_url         = "${module.ecr.repository_url}:${var.image_tag}"
}

module "apprunner" {
  count  = var.enable_apprunner ? 1 : 0
  source = "./modules/apprunner"

  service_name   = var.apprunner_service_name
  image_url      = var.apprunner_image_url
  port           = var.apprunner_port
  cpu            = var.apprunner_cpu
  memory         = var.apprunner_memory
  health_path    = var.apprunner_health_path
  auto_deploy    = var.apprunner_auto_deploy
  env_vars       = var.apprunner_env_vars
}
