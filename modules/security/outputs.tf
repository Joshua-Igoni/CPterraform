output "alb_sg_id" { value = aws_security_group.alb.id }
output "ecs_sg_id" { value = aws_security_group.ecs.id }
output "db_sg_id"  { value = aws_security_group.db.id }
output "exec_permissions_boundary_arn" {
  value = var.exec_permissions_boundary_arn != "" ? var.exec_permissions_boundary_arn : aws_iam_policy.exec_boundary[0].arn
}