variable "name" {
  description = "ECS cluster name"
  type        = string
}

variable "tags" {
  description = "Tags applied to ECS resources"
  type        = map(string)
  default     = {}
}
