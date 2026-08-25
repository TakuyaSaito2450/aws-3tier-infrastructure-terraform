# ============================================================
# database モジュール
#   DB Subnet Group / RDS (MySQL) / パスワード管理
# ------------------------------------------------------------
# 設計判断:
#   - パスワードは manage_master_user_password で Secrets Manager に
#     管理させる。tfvars や state に平文を置かないため。
#   - multi_az は変数化。検証時は false でコストを抑え、本番相当の
#     デモをする際に true へ切り替える。
#   - 削除保護は環境変数で制御。dev では destroy を通したいので既定 false。
# ============================================================

locals {
  common_tags = merge(var.tags, { Module = "database" })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-dbsng"
  subnet_ids = var.data_subnet_ids

  tags = merge(local.common_tags, { Name = "${var.name_prefix}-dbsng" })
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.name_prefix}-dbpg"
  family = var.parameter_group_family

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name_prefix}-rds"
  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.master_username

  # 平文パスワードを持たず、Secrets Managerに管理を委ねる
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name
  vpc_security_group_ids = [var.data_sg_id]
  port                   = var.db_port
  publicly_accessible    = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window           = "17:00-18:00" # UTC (JST 02:00-03:00)
  maintenance_window       = "sun:18:00-sun:19:00"

  auto_minor_version_upgrade = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : "${var.name_prefix}-rds-final"

  enabled_cloudwatch_logs_exports = ["error", "slowquery"]

  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(local.common_tags, { Name = "${var.name_prefix}-rds" })
}
