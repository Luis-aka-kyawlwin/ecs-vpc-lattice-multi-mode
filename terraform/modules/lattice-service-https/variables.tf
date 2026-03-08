variable "name" {
  type = string
}

variable "service_network_id" {
  type = string
}

variable "target_vpc_id" {
  type = string
}

variable "target_port" {
  type    = number
  default = 8080
}

variable "certificate_arn" {
  description = "ACM certificate ARN used by VPC Lattice listener"
  type        = string
}

variable "custom_domain_name" {
  description = "Custom domain name for VPC Lattice service when using certificate_arn"
  type        = string
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "tags" {
  type    = map(string)
  default = {}
}
