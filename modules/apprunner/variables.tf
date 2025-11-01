variable "service_name" { type = string }
variable "image_url"    { type = string }
variable "port"         { type = number }
variable "cpu"          { type = string }
variable "memory"       { type = string }
variable "health_path"  { type = string }
variable "auto_deploy"  { type = bool }
variable "env_vars"     { type = map(string) }
