resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP from Internet"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs" {
  name   = "ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port                = 8000
    to_port                  = 8000
    protocol                 = "tcp"
    security_groups          = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name   = "db-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port                = 5432
    to_port                  = 5432
    protocol                 = "tcp"
    security_groups          = [aws_security_group.ecs.id]
  }
}

# (optional) execution role boundary placeholder
resource "aws_iam_policy" "exec_boundary" {
  count       = var.exec_permissions_boundary_arn == "" ? 1 : 0
  name        = "ecs-exec-boundary"
  description = "Minimal boundary allowing ecsTaskExecutionRole basic calls"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "*",
      Resource = "*"
    }]
  })
}
