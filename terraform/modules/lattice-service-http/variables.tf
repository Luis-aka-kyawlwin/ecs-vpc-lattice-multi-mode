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

variable "target_protocol" {
  type    = string
  default = "HTTP"
}

variable "listener_port" {
  type    = number
  default = 80
}

variable "health_check_protocol" {
  type    = string
  default = "HTTP"
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "tags" {
  type    = map(string)
  default = {}
}
