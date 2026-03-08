data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = merge(var.tags, {
    Project = "vpc-lattice-ecs-demo"
    Mode    = "mode-b-https"
  })
}

module "vpc_dashboard" {
  source = "../../modules/vpc"

  name                 = "${var.name_prefix}-dashboard"
  cidr_block           = var.dashboard_vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = ["10.30.0.0/24", "10.30.1.0/24"]
  private_subnet_cidrs = ["10.30.10.0/24", "10.30.11.0/24"]
  enable_nat_gateway   = var.enable_nat_gateway
  tags                 = local.common_tags
}

module "vpc_counting" {
  source = "../../modules/vpc"

  name                 = "${var.name_prefix}-counting"
  cidr_block           = var.counting_vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = ["10.40.0.0/24", "10.40.1.0/24"]
  private_subnet_cidrs = ["10.40.10.0/24", "10.40.11.0/24"]
  enable_nat_gateway   = var.enable_nat_gateway
  tags                 = local.common_tags
}

resource "aws_security_group" "dashboard" {
  name        = "${var.name_prefix}-dashboard-sg"
  description = "Dashboard ECS service security group"
  vpc_id      = module.vpc_dashboard.vpc_id

  dynamic "ingress" {
    for_each = var.enable_public_alb ? [1] : []
    content {
      from_port       = 9002
      to_port         = 9002
      protocol        = "tcp"
      security_groups = [aws_security_group.dashboard_alb[0].id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "dashboard_alb" {
  count = var.enable_public_alb ? 1 : 0

  name        = "${var.name_prefix}-dashboard-alb-sg"
  description = "Public ALB security group for dashboard service"
  vpc_id      = module.vpc_dashboard.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidr_blocks
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "counting" {
  name        = "${var.name_prefix}-counting-sg"
  description = "Counting ECS service security group"
  vpc_id      = module.vpc_counting.vpc_id

  ingress {
    from_port   = var.counting_service_port
    to_port     = var.counting_service_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_lb" "dashboard" {
  count = var.enable_public_alb ? 1 : 0

  name               = "${var.name_prefix}-dash-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dashboard_alb[0].id]
  subnets            = module.vpc_dashboard.public_subnet_ids

  tags = local.common_tags
}

resource "aws_lb_target_group" "dashboard" {
  count = var.enable_public_alb ? 1 : 0

  name        = "${var.name_prefix}-dash-tg"
  port        = 9002
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc_dashboard.vpc_id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = local.common_tags
}

resource "aws_lb_listener" "dashboard_http" {
  count = var.enable_public_alb ? 1 : 0

  load_balancer_arn = aws_lb.dashboard[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "dashboard_https" {
  count = var.enable_public_alb ? 1 : 0

  load_balancer_arn = aws_lb.dashboard[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dashboard[0].arn
  }
}

module "cluster_dashboard" {
  source = "../../modules/ecs-cluster"

  name = "${var.name_prefix}-dashboard"
  tags = local.common_tags
}

module "cluster_counting" {
  source = "../../modules/ecs-cluster"

  name = "${var.name_prefix}-counting"
  tags = local.common_tags
}

module "lattice_network" {
  source = "../../modules/lattice-service-network"

  name    = "${var.name_prefix}-sn"
  vpc_ids = [module.vpc_dashboard.vpc_id, module.vpc_counting.vpc_id]
  tags    = local.common_tags
}

module "lattice_service" {
  source = "../../modules/lattice-service-https"

  name               = var.name_prefix
  service_network_id = module.lattice_network.service_network_id
  target_vpc_id      = module.vpc_counting.vpc_id
  target_port        = var.counting_service_port
  certificate_arn    = var.certificate_arn
  custom_domain_name = var.custom_domain_name
  tags               = local.common_tags
}

module "counting_service" {
  source = "../../modules/ecs-service"

  name                     = "${var.name_prefix}-counting"
  cluster_arn              = module.cluster_counting.cluster_arn
  container_image          = var.counting_image
  container_port           = var.counting_service_port
  desired_count            = 1
  subnet_ids               = module.vpc_counting.public_subnet_ids
  security_group_ids       = [aws_security_group.counting.id]
  assign_public_ip         = true
  lattice_target_group_arn = module.lattice_service.target_group_arn
  enable_lattice           = true
  environment = {
    APP_MODE = "mode-b-https"
    PORT     = tostring(var.counting_service_port)
  }
  tags = local.common_tags
}

module "dashboard_service" {
  source = "../../modules/ecs-service"

  name                 = "${var.name_prefix}-dashboard"
  cluster_arn          = module.cluster_dashboard.cluster_arn
  container_image      = var.dashboard_image
  container_port       = 9002
  desired_count        = 1
  subnet_ids           = module.vpc_dashboard.public_subnet_ids
  security_group_ids   = [aws_security_group.dashboard.id]
  assign_public_ip     = true
  alb_target_group_arn = var.enable_public_alb ? aws_lb_target_group.dashboard[0].arn : null
  environment = {
    APP_MODE             = "mode-b-https"
    PORT                 = "9002"
    COUNTING_SERVICE_URL = "https://${module.lattice_service.service_dns_name}"
  }
  tags = local.common_tags
}
