variable "name_prefix"       { type = string }
variable "vpc_id"            { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids"{ type = list(string) }

variable "container_port"    { type = number }
variable "desired_count"     { type = number }
variable "task_cpu"          { type = number }
variable "task_memory"       { type = number }
variable "health_check_path" { type = string }

variable "image_url"         { type = string }
