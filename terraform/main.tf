terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "sagemaker-secure-pipeline"
      ManagedBy = "terraform"
      Owner     = var.owner_tag
    }
  }
}

module "vpc" {
  source = "./modules/vpc"
  prefix = var.prefix
}

module "kms" {
  source     = "./modules/kms"
  prefix     = var.prefix
  aws_region = var.aws_region
}

module "iam" {
  source               = "./modules/iam"
  prefix               = var.prefix
  training_bucket_arn  = module.s3.training_bucket_arn
  artifacts_bucket_arn = module.s3.artifacts_bucket_arn
  kms_key_arn          = module.kms.key_arn
}

module "s3" {
  source              = "./modules/s3"
  prefix              = var.prefix
  kms_key_arn         = module.kms.key_arn
  vpc_endpoint_id     = module.vpc.s3_endpoint_id
}

module "sagemaker" {
  source                       = "./modules/sagemaker"
  prefix                       = var.prefix
  execution_role_arn           = module.iam.execution_role_arn
  subnet_id                    = module.vpc.private_subnet_id
  security_group_id            = module.vpc.sagemaker_sg_id
  kms_key_arn                  = module.kms.key_arn
  training_bucket              = module.s3.training_bucket_name
  artifacts_bucket             = module.s3.artifacts_bucket_name
  autopilot_max_runtime_seconds = var.autopilot_max_runtime_seconds
}

module "monitoring" {
  source        = "./modules/monitoring"
  prefix        = var.prefix
  endpoint_name = local.endpoint_name
}
