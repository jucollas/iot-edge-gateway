resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.lab_role_arn
  task_role_arn            = var.lab_role_arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.ecr_repository_url}:latest"
      essential = true
      environment = [
        {
          name  = "AWS_REGION"
          value = "us-east-1"
        },
        {
          name  = "SENSORS_TABLE"
          value = var.sensors_table_name
        },
        {
          name  = "SENSOR_DATA_TABLE"
          value = var.sensor_data_table_name
        },
        {
          name  = "DB_HOST"
          value = var.postgres_endpoint
        },
        {
          name  = "DB_NAME"
          value = var.postgres_database
        },
        {
          name  = "DB_USER"
          value = var.postgres_username
        },
        {
          name  = "DB_PASSWORD"
          value = var.postgres_password
        }
      ]

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-task-def"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.ecs_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = 8000
  }

  tags = {
    Name        = "${var.project_name}-service"
    Environment = var.environment
  }
}