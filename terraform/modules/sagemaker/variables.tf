variable "prefix" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

variable "training_bucket" {
  type = string
}

variable "artifacts_bucket" {
  type = string
}

variable "autopilot_max_runtime_seconds" {
  type = number
}
