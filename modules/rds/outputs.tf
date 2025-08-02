output "db_endpoint"  { value = aws_db_instance.postgres.address }
output "db_secret_arn"{ value = aws_secretsmanager_secret.db_pass.arn }