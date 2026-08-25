variable "name_prefix" {
  description = "リソース名の接頭辞"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "ALBを配置するサブネットID"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "EC2を配置するサブネットID"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB用SGのID"
  type        = string
}

variable "app_sg_id" {
  description = "app層用SGのID"
  type        = string
}

variable "instance_profile_name" {
  description = "EC2にアタッチするインスタンスプロファイル名"
  type        = string
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "ルートEBSのサイズ(GiB)"
  type        = number
  default     = 20
}

variable "app_port" {
  description = "アプリケーションの待受ポート"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "ALBヘルスチェックのパス"
  type        = string
  default     = "/health"
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

variable "cpu_target_value" {
  description = "ターゲット追跡スケーリングの目標CPU使用率(%)"
  type        = number
  default     = 60
}

variable "detailed_monitoring" {
  description = "EC2詳細モニタリング(1分間隔)を有効にするか。有効時は課金対象。"
  type        = bool
  default     = false
}

variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}
