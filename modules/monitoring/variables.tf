variable "name_prefix" {
  description = "リソース名の接頭辞"
  type        = string
}

variable "region" {
  description = "ダッシュボード表示対象のリージョン"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALBのメトリクス識別子"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "TargetGroupのメトリクス識別子"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group名"
  type        = string
}

variable "db_identifier" {
  description = "RDSインスタンス識別子"
  type        = string
}

variable "alert_email" {
  description = "アラート通知先メールアドレス (nullで購読なし)"
  type        = string
  default     = null
}

variable "alb_5xx_threshold" {
  description = "ALB 5xx のアラーム閾値(5分間の合計)"
  type        = number
  default     = 5
}

variable "rds_cpu_threshold" {
  description = "RDS CPU使用率のアラーム閾値(%)"
  type        = number
  default     = 80
}

variable "rds_free_storage_threshold_bytes" {
  description = "RDS空きストレージのアラーム閾値(バイト)"
  type        = number
  default     = 2147483648 # 2GiB
}

variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}
