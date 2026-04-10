variable "prefix" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "model_package_arn" {
  description = "ARN of the approved model package from the pipeline run"
  type        = string
}

variable "endpoint_instance_type" {
  type    = string
  default = "ml.m5.xlarge"
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

variable "artifacts_bucket" {
  type = string
}
