variable "name" {
  description = "VPC Lattice service network name"
  type        = string
}

variable "vpc_ids" {
  description = "VPC IDs associated with the service network"
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}
