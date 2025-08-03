output "alb_dns" {
  value = module.alb.dns_name
}

output "db_endpoint" {
  value = module.rds.db_endpoint
}

output "secret_arn" {
  value     = module.rds.db_secret_arn
  sensitive = true
}

output "ecs_exec_hint" {
  value = "aws ecs execute-command --cluster ${module.ecs.cluster_name} --task <TASK_ARN> --interactive --command \"/bin/sh\""
}

output "static_bucket_name" {
  description = "Name of the S3 bucket that stores collected static files"
  value       = module.edge.static_bucket_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain"
  value       = module.edge.cloudfront_domain_name
}