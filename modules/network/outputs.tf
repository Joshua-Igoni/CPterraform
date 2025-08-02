output "vpc_id"                 { value = aws_vpc.this.id }
output "public_subnet_ids"      { value = aws_subnet.public[*].id }
output "db_private_subnet_ids"  { value = aws_subnet.db[*].id }
output "ecs_private_subnet_ids" { value = aws_subnet.ecs[*].id }