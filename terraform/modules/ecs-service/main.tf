locals {
  use_custom_execution_role = var.task_execution_role_arn != null
  use_custom_task_role      = var.task_role_arn != null
}

data "aws_region" "current" {}

data "aws_iam_policy_document" "ecs_task_execution_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  count = local.use_custom_execution_role ? 0 : 1

  name               = "${var.name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_default" {
  count = local.use_custom_execution_role ? 0 : 1

  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  count = local.use_custom_task_role ? 0 : 1

  name               = "${var.name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume.json

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/service/${var.name}"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_iam_role" "ecs_infrastructure" {
  count = var.enable_lattice ? 1 : 0

  name = "${var.name}-ecs-infra-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_infrastructure_vpc_lattice" {
  count = var.enable_lattice ? 1 : 0

  role       = aws_iam_role.ecs_infrastructure[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForVpcLattice"
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)

  execution_role_arn = local.use_custom_execution_role ? var.task_execution_role_arn : aws_iam_role.execution[0].arn
  task_role_arn      = local.use_custom_task_role ? var.task_role_arn : aws_iam_role.task[0].arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.container_image
      essential = true
      portMappings = [
        {
          name          = "app"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        for k, v in var.environment : {
          name  = k
          value = v
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.alb_target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.alb_target_group_arn
      container_name   = var.name
      container_port   = var.container_port
    }
  }

  dynamic "vpc_lattice_configurations" {
    for_each = var.enable_lattice ? [1] : []
    content {
      target_group_arn = var.lattice_target_group_arn
      role_arn         = aws_iam_role.ecs_infrastructure[0].arn
      port_name        = "app"
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.execution_default,
    aws_iam_role_policy_attachment.ecs_infrastructure_vpc_lattice
  ]
}
