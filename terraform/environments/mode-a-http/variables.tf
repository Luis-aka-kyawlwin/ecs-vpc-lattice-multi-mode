variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "vpc-lattice-ecs-demo-a"
}

variable "dashboard_image" {
  type        = string
  description = "Dashboard container image"
}

variable "counting_image" {
  type        = string
  description = "Counting container image"
}

variable "dashboard_vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "counting_vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "tags" {
  type    = map(string)
  default = {}
}
