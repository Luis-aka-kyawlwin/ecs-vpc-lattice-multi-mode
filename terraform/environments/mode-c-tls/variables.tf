variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "vpc-lattice-ecs-demo-c"
}

variable "dashboard_image" {
  type = string
}

variable "counting_image" {
  type = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for compatibility HTTPS listener in mode-c stack"
  type        = string
}

variable "dashboard_vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "counting_vpc_cidr" {
  type    = string
  default = "10.60.0.0/16"
}

variable "counting_service_port" {
  type    = number
  default = 9003
}

variable "tags" {
  type    = map(string)
  default = {}
}
