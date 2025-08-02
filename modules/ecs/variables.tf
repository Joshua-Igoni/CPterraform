variable "name"                 { type = string }
variable "vpc_id"               { type = string }
variable "private_subnet_ids"   { type = list(string) }
variable "task_sg_id"           { type = string }
variable "execution_permissions_boundary_arn" { 
    type = string 
    default = "" 
}
variable "container_image"      { type = string }
variable "db_endpoint"          { type = string }
variable "db_user"              { type = string }
variable "secret_arn"           { type = string }
variable "alb_target_group_arn" { type = string }
variable "container_port"       { 
    type = number 
    default = 8000 
}