data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = merge(var.tags, {
    Project = "vpc-lattice-ecs-demo"
    Mode    = "mode-c-tls"
  })
}

module "vpc_dashboard" {
  source = "../../modules/vpc"

  name                 = "${var.name_prefix}-dashboard"
  cidr_block           = var.dashboard_vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = ["10.50.0.0/24", "10.50.1.0/24"]
  private_subnet_cidrs = ["10.50.10.0/24", "10.50.11.0/24"]
  enable_nat_gateway   = true
  tags                 = local.common_tags
}

module "vpc_counting" {
  source = "../../modules/vpc"

  name                 = "${var.name_prefix}-counting"
  cidr_block           = var.counting_vpc_cidr
  azs                  = local.azs
  public_subnet_cidrs  = ["10.60.0.0/24", "10.60.1.0/24"]
  private_subnet_cidrs = ["10.60.10.0/24", "10.60.11.0/24"]
  enable_nat_gateway   = true
  tags                 = local.common_tags
}

resource "aws_security_group" "dashboard" {
  name        = "${var.name_prefix}-dashboard-sg"
  description = "Dashboard ECS service security group"
  vpc_id      = module.vpc_dashboard.vpc_id

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
  # Compatibility mode for current applications (HTTP backend).
  # True TLS passthrough requires the counting container to terminate TLS itself.
  source = "../../modules/lattice-service-https"

  name               = var.name_prefix
  service_network_id = module.lattice_network.service_network_id
  target_vpc_id      = module.vpc_counting.vpc_id
  target_port        = var.counting_service_port
  certificate_arn    = var.certificate_arn
  tags               = local.common_tags
}

module "counting_service" {
  source = "../../modules/ecs-service"

  name                     = "${var.name_prefix}-counting"
  cluster_arn              = module.cluster_counting.cluster_arn
  container_image          = var.counting_image
  container_port           = var.counting_service_port
  desired_count            = 1
  subnet_ids               = module.vpc_counting.private_subnet_ids
  security_group_ids       = [aws_security_group.counting.id]
  lattice_target_group_arn = module.lattice_service.target_group_arn
  enable_lattice           = true
  environment = {
    APP_MODE = "mode-c-tls"
    PORT     = tostring(var.counting_service_port)
  }
  tags = local.common_tags
}

module "dashboard_service" {
  source = "../../modules/ecs-service"

  name               = "${var.name_prefix}-dashboard"
  cluster_arn        = module.cluster_dashboard.cluster_arn
  container_image    = var.dashboard_image
  container_port     = 9002
  desired_count      = 1
  subnet_ids         = module.vpc_dashboard.private_subnet_ids
  security_group_ids = [aws_security_group.dashboard.id]
  environment = {
    APP_MODE             = "mode-c-tls"
    PORT                 = "9002"
    COUNTING_SERVICE_URL = "https://${module.lattice_service.service_dns_name}"
  }
  tags = local.common_tags
}
