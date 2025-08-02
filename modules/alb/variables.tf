variable "vpc_id"            { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id"         { type = string }
variable "target_sg_id"      { type = string }
variable "name"              { type = string }
variable "port"              { 
    type = number 
    default = 8000 
}
variable "health_path"       { 
    type = string 
    default = "/healthz/" 
}