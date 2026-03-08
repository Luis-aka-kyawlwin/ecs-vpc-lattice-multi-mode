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
  default = 8443
}

variable "health_check_port" {
  type    = number
  default = 8080
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "tags" {
  type    = map(string)
  default = {}
}
