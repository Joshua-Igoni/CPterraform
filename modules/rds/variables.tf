variable "vpc_id"            { type = string }
variable "subnet_ids"        { type = list(string) }
variable "security_group_id" { type = string }
variable "db_username"       { type = string }
variable "db_password"       { 
    type = string 
    sensitive = true 
}
variable "db_name" {
  type    = string
  default = "notejam"
}
variable "multi_az" {
  type        = bool
  default     = true      
  description = "If true, deploy an RDS Multi-AZ standby in another AZ"
}
variable "name"              { type = string }