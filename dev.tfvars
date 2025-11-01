github_owner = "atorossian"
app_repo_name = "household-finances"
infra_repo_name = "infra-household-finances"
main_branch = "main"
image_tag = "latest"
container_port = 8080
health_check_path = "/health"

enable_apprunner       = true
apprunner_service_name = "hf-dev-apprunner"
apprunner_image_url    = "378779692580.dkr.ecr.eu-west-1.amazonaws.com/household-finances:dev"
apprunner_port         = 8080
apprunner_health_path = "/health"
apprunner_cpu          = "0.25 vCPU"
apprunner_memory       = "512"
apprunner_auto_deploy  = true
apprunner_env_vars = {
  ENV        = "dev"
  SECRET_KEY = "dev-please-rotate" # use a stronger value later
}


