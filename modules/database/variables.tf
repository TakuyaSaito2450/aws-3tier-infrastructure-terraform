variable "name_prefix" {
  description = "リソース名の接頭辞"
  type        = string
}

variable "data_subnet_ids" {
  description = "RDSを配置するサブネットID (2AZ以上)"
  type        = list(string)

  validation {
    condition     = length(var.data_subnet_ids) >= 2
    error_message = "DB Subnet Group には2AZ以上のサブネットが必要です。"
  }
}

variable "data_sg_id" {
  description = "RDS用SGのID"
  type        = string
}

variable "engine_version" {
  description = "MySQLのエンジンバージョン"
  type        = string
  default     = "8.0"
}

variable "parameter_group_family" {
  description = "パラメータグループのファミリー"
  type        = string
  default     = "mysql8.0"
}

variable "instance_class" {
  description = "RDSインスタンスクラス"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "初期ストレージ容量(GiB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "ストレージ自動拡張の上限(GiB)"
  type        = number
  default     = 50
}

variable "db_name" {
  description = "初期データベース名"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "マスターユーザー名"
  type        = string
  default     = "admin"
}

variable "db_port" {
  description = "待受ポート"
  type        = number
  default     = 3306
}

variable "multi_az" {
  description = "Multi-AZ配置にするか (true=可用性優先 / false=コスト優先)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "自動バックアップの保持日数 (0で無効)"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "削除保護"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "削除時に最終スナップショットを省略するか"
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Performance Insightsを有効にするか"
  type        = bool
  default     = false
}

variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}
