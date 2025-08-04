# IAM roles
resource "aws_iam_role" "execution" {
  name                 = "${var.name}-exec-role"
  permissions_boundary = var.execution_permissions_boundary_arn != "" ? var.execution_permissions_boundary_arn : null
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "exec_default" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "exec_secrets" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role" "task" {
  name                 = "${var.name}-task-role"
  permissions_boundary = var.execution_permissions_boundary_arn != "" ? var.execution_permissions_boundary_arn : null
  assume_role_policy   = aws_iam_role.execution.assume_role_policy
}

resource "aws_iam_role_policy" "task_ssm" {
  name = "ssm-messages"
  role = aws_iam_role.task.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ],
      Resource = "*"
    }]
  })
}

# ECS cluster
resource "aws_ecs_cluster" "this" { name = "${var.name}-cluster" }

# Task definition
locals {
  container_defs = jsonencode([
     # --- init container: runs migrations then exits ---
  {
    name      = "${var.name}-migrate"
    image     = var.container_image
    essential = false
    command   = ["sh","-c","python notejam/manage.py migrate --noinput || true"]

    environment = [
      { name = "POSTGRES_HOST", value = var.db_endpoint },
      { name = "POSTGRES_PORT", value = "5432" },
      { name = "POSTGRES_USER", value = var.db_user     },
      { name = "POSTGRES_DB",   value = var.name        }
    ]

    secrets = [{
      name      = "POSTGRES_PASSWORD"
      valueFrom = var.secret_arn
    }]
  },
        # --- main application container ---
    {
      name      = "${var.name}"
      image     = var.container_image
      essential = true
      portMappings = [{ containerPort = var.container_port, hostPort = var.container_port, protocol = "tcp" }]

      environment = [
        { name = "POSTGRES_HOST", value = var.db_endpoint },
        { name = "POSTGRES_PORT", value = "5432" },
        { name = "POSTGRES_USER", value = var.db_user },
        { name = "POSTGRES_DB",   value = var.name },
        { name = "DJANGO_ALLOWED_HOSTS", value = "*" },
        { name = "CLOUDFRONT_DOMAIN", value = var.cloudfront_domain_name}
      ]
      secrets = [{ name = "POSTGRES_PASSWORD", valueFrom = var.secret_arn }]
    }
  ])
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.name
  cpu                      = "2048"
  memory                   = "5120"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions    = local.container_defs
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
}

# Service
resource "aws_ecs_service" "this" {
  name                               = var.name
  cluster                            = aws_ecs_cluster.this.id
  task_definition                    = aws_ecs_task_definition.app.arn
  launch_type                        = "FARGATE"
  desired_count                      = 2
  enable_execute_command             = true
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.task_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.name
    container_port   = var.container_port
  }
}