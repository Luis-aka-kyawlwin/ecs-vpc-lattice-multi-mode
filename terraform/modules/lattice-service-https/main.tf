resource "aws_vpclattice_target_group" "this" {
  name = "${var.name}-https-tg"
  type = "IP"

  config {
    protocol         = "HTTP"
    protocol_version = "HTTP1"
    port             = var.target_port
    vpc_identifier   = var.target_vpc_id

    health_check {
      enabled                   = true
      protocol                  = "HTTP"
      path                      = var.health_check_path
      port                      = var.target_port
      healthy_threshold_count   = 2
      unhealthy_threshold_count = 2
      matcher {
        value = "200-399"
      }
    }
  }

  tags = var.tags
}

resource "aws_vpclattice_service" "this" {
  name               = "${var.name}-https"
  auth_type          = "NONE"
  certificate_arn    = var.certificate_arn
  custom_domain_name = var.custom_domain_name

  tags = var.tags
}

resource "aws_vpclattice_listener" "this" {
  name               = "https"
  protocol           = "HTTPS"
  port               = 443
  service_identifier = aws_vpclattice_service.this.id

  default_action {
    forward {
      target_groups {
        target_group_identifier = aws_vpclattice_target_group.this.id
        weight                  = 100
      }
    }
  }

  tags = var.tags
}

resource "aws_vpclattice_service_network_service_association" "this" {
  service_identifier         = aws_vpclattice_service.this.id
  service_network_identifier = var.service_network_id

  tags = var.tags
}
