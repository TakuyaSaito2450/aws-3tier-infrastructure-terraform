# ---- 基本 ----
variable "project" {
  description = "プロジェクト名 (リソース名の接頭辞に使用)"
  type        = string
  default     = "portfolio"
}

variable "env" {
  description = "環境識別子 (dev / stg / prd)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "リソース所有者 (タグ用)"
  type        = string
}

variable "region" {
  description = "デプロイ先リージョン"
  type        = string
  default     = "ap-northeast-1"
}

# ---- ネットワーク ----
variable "vpc_cidr" {
  description = "VPCのCIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "使用するAZ数"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "NAT Gatewayを作成するか"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "NAT Gatewayを1台に集約するか"
  type        = bool
  default     = true
}

variable "ingress_cidr" {
  description = "ALBへのアクセスを許可するCIDR"
  type        = string
  default     = "0.0.0.0/0"
}

# ---- アプリケーション ----
variable "app_port" {
  description = "アプリの待受ポート"
  type        = number
  default     = 80
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "ASG最小台数"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "ASG最大台数"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "ASG希望台数"
  type        = number
  default     = 2
}

# ---- データベース ----
variable "db_instance_class" {
  description = "RDSインスタンスクラス"
  type        = string
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  description = "RDSをMulti-AZにするか"
  type        = bool
  default     = false
}

variable "db_port" {
  description = "DBの待受ポート"
  type        = number
  default     = 3306
}

variable "db_backup_retention_period" {
  description = "自動バックアップ保持日数"
  type        = number
  default     = 7
}

# ---- 監視 ----
variable "alert_email" {
  description = "アラート通知先メールアドレス"
  type        = string
  default     = null
}
