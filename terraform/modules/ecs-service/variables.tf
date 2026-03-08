variable "name" {
  description = "Service name"
  type        = string
}

variable "cluster_arn" {
  description = "ECS cluster ARN"
  type        = string
}

variable "container_image" {
  description = "Container image"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "desired_count" {
  description = "Number of desired tasks"
  type        = number
  default     = 1
}

variable "cpu" {
  description = "Task CPU"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory"
  type        = number
  default     = 512
}

variable "subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attached to tasks"
  type        = list(string)
}

variable "assign_public_ip" {
  description = "Assign public IP"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Container environment variables"
  type        = map(string)
  default     = {}
}

variable "task_execution_role_arn" {
  description = "Optional execution role ARN"
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "Optional task role ARN"
  type        = string
  default     = null
}

variable "lattice_target_group_arn" {
  description = "Optional VPC Lattice target group ARN"
  type        = string
  default     = null
}

variable "enable_lattice" {
  description = "Enable VPC Lattice integration for this ECS service"
  type        = bool
  default     = false
}

variable "alb_target_group_arn" {
  description = "Optional ALB target group ARN for ECS service registration"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}
