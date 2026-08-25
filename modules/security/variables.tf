variable "name_prefix" {
  description = "リソース名の接頭辞"
  type        = string
}

variable "vpc_id" {
  description = "SGを作成するVPCのID"
  type        = string
}

variable "ingress_cidr" {
  description = "ALBへのアクセスを許可するCIDR (検証時は自宅IP/32を推奨)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "app_port" {
  description = "アプリケーションの待受ポート"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "データベースの待受ポート"
  type        = number
  default     = 3306
}

variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}
