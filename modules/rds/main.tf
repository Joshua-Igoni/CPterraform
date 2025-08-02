resource "random_id" "suffix" {
  byte_length = 2   
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-sng"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "postgres" {
  identifier              = "${var.name}-db"
  engine                  = "postgres"
  #engine_version          = "16.2"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  username                = var.db_username
  password                = var.db_password
  db_name                 = var.db_name
  db_subnet_group_name    = aws_db_subnet_group.this.name
  multi_az                = var.multi_az
  vpc_security_group_ids  = [var.security_group_id]
  skip_final_snapshot     = true
  publicly_accessible     = false
}

resource "aws_secretsmanager_secret" "db_pass" {
  name = "${var.name}/postgres-${random_id.suffix.hex}"
}

resource "aws_secretsmanager_secret_version" "dbpass" {
  secret_id     = aws_secretsmanager_secret.db_pass.id
  secret_string = var.db_password
}
