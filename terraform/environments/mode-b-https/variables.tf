variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "vpc-lattice-ecs-demo-b"
}

variable "dashboard_image" {
  type = string
}

variable "counting_image" {
  type = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (imported from local OpenSSL cert)"
  type        = string
}

variable "custom_domain_name" {
  description = "Custom domain name attached to mode-b VPC Lattice service."
  type        = string
}

variable "counting_service_port" {
  description = "Counting service backend port"
  type        = number
  default     = 9003
}

variable "dashboard_vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "counting_vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT gateway for mode-b VPCs (cost impact)."
  type        = bool
  default     = false
}

variable "enable_public_alb" {
  description = "Create internet-facing ALB for public access to dashboard service."
  type        = bool
  default     = true
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access public ALB listener."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
