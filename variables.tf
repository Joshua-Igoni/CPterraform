variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "app_name" {
  type    = string
  default = "notejam"
}

variable "db_username" {
  type    = string
  default = "notejam"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "container_image" {
  type    = string
  default = "885952650506.dkr.ecr.eu-central-1.amazonaws.com/cpapp:latest"
}

variable "exec_permissions_boundary_arn" {
  type    = string
  default = ""
  description = "(Optional) ARN of an IAM permissions boundary to attach to exec/task roles"
}