variable "vpc_id"                    { type = string }
variable "alb_subnet_ids"            { type = list(string) }
variable "ecs_private_subnet_ids"    { type = list(string) }
variable "db_private_subnet_ids"     { type = list(string) }
variable "exec_permissions_boundary_arn" { 
    type = string 
    default = "" 
}