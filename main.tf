data "aws_caller_identity" "this" {}

module "network" {
  source   = "./modules/network"
  name     = var.app_name
  az_count = 3
}

module "security" {
  source                              = "./modules/security"
  vpc_id                              = module.network.vpc_id
  alb_subnet_ids                      = module.network.public_subnet_ids
  ecs_private_subnet_ids              = module.network.ecs_private_subnet_ids
  db_private_subnet_ids               = module.network.db_private_subnet_ids
  exec_permissions_boundary_arn       = var.exec_permissions_boundary_arn
}

module "rds" {
  source            = "./modules/rds"
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.db_private_subnet_ids
  security_group_id = module.security.db_sg_id
  db_username       = var.db_username
  db_password       = var.db_password
  name              = var.app_name
}

module "edge" {
  source = "./modules/edge"

  app_name      = var.app_name
  alb_domain_name = module.alb.lb_dns_name
  alb_dns_name    = module.alb.dns_name
  tags           = local.tags
}

output "cdn_url" {
  description = "Default CloudFront URL"
  value       = module.edge.cloudfront_domain_name
}


module "alb" {
  source            = "./modules/alb"
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  target_sg_id      = module.security.ecs_sg_id
  health_path       = "/healthz/"
  port              = 8000
  name              = var.app_name
}

module "ecs" {
  source                               = "./modules/ecs"
  name                                 = var.app_name
  vpc_id                               = module.network.vpc_id
  private_subnet_ids                   = module.network.ecs_private_subnet_ids
  task_sg_id                           = module.security.ecs_sg_id
  execution_permissions_boundary_arn   = var.exec_permissions_boundary_arn
  container_image                      = var.container_image
  db_endpoint                          = module.rds.db_endpoint
  db_user                              = var.db_username
  secret_arn                           = module.rds.db_secret_arn
  alb_target_group_arn                 = module.alb.target_group_arn
  container_port                       = 8000
  cloudfront_domain_name               = module.edge.cloudfront_domain_name
}