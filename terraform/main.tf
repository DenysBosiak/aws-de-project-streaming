data "aws_caller_identity" "current" {}

module "storage" {
  source = "./modules/storage"
  env = var.env
}

module "iam" {
  source = "./modules/iam"
  env = var.env
  raw_bucket_arn = module.storage.raw_bucket_arn
  script_bucket_arn = module.storage.script_bucket_arn
}

module "compute" {
  source = "./modules/compute"
  env = var.env
  lambda_role_arn = module.iam.lambda_exec_arn
  firehose_role_arn = module.iam.firehose_role_arn
  raw_bucket_id = module.storage.raw_bucket_id
}

module "analytics" {
  source = "./modules/analytics"
  env = var.env
  rs_admin_user = var.rs_admin_user
  rs_admin_password = var.rs_admin_password
  private_subnet_ids = var.private_subnet_ids
  vpc_id = var.vpc_id
}