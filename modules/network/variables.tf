variable "name_prefix" {
  description = "リソース名の接頭辞 (例: portfolio-dev)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr は有効なCIDR表記で指定してください。"
  }
}

variable "az_count" {
  description = "使用するAZ数 (ALB/RDS Multi-AZの最小要件は2)"
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count は 2 または 3 を指定してください。"
  }
}

variable "enable_nat_gateway" {
  description = "NAT Gatewayを作成するか"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "NAT Gatewayを1台に集約するか (true=コスト優先 / false=可用性優先)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "共通タグ"
  type        = map(string)
  default     = {}
}
