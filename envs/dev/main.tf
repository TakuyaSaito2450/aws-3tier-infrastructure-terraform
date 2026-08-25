# ============================================================
# dev 環境のルートモジュール
#   3層Web基盤 (ALB + EC2/ASG + RDS) の組み立て
# ------------------------------------------------------------
# 環境の差分は terraform.tfvars のみで表現し、
# main.tf は dev/prd で共通にする方針。
# ============================================================

locals {
  name_prefix = "${var.project}-${var.env}"

  common_tags = {
    Project   = var.project
    Env       = var.env
    ManagedBy = "terraform"
    Owner     = var.owner
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  tags               = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name_prefix  = local.name_prefix
  vpc_id       = module.network.vpc_id
  ingress_cidr = var.ingress_cidr
  app_port     = var.app_port
  db_port      = var.db_port
  tags         = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  name_prefix           = local.name_prefix
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  app_subnet_ids        = module.network.app_subnet_ids
  alb_sg_id             = module.security.alb_sg_id
  app_sg_id             = module.security.app_sg_id
  instance_profile_name = module.security.app_instance_profile_name

  instance_type    = var.instance_type
  app_port         = var.app_port
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  tags = local.common_tags
}

module "database" {
  source = "../../modules/database"

  name_prefix     = local.name_prefix
  data_subnet_ids = module.network.data_subnet_ids
  data_sg_id      = module.security.data_sg_id

  instance_class          = var.db_instance_class
  multi_az                = var.db_multi_az
  db_port                 = var.db_port
  backup_retention_period = var.db_backup_retention_period

  tags = local.common_tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix             = local.name_prefix
  region                  = var.region
  alb_arn_suffix          = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix
  asg_name                = module.compute.asg_name
  db_identifier           = module.database.db_identifier
  alert_email             = var.alert_email

  tags = local.common_tags
}
