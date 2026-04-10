locals {
  training_bucket      = "${var.prefix}-training-data"
  artifacts_bucket     = "${var.prefix}-model-artifacts"
  role_name            = "${var.prefix}-execution-role"
  model_package_group  = "${var.prefix}-models"
  pipeline_name        = "${var.prefix}-pipeline"
  endpoint_name        = "${var.prefix}-endpoint"
  endpoint_config_name = "${var.prefix}-endpoint-config"
  kms_alias            = "alias/${var.prefix}"
  target_attribute     = "repaid"
}
