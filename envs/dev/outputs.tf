output "alb_url" {
  description = "動作確認用URL"
  value       = "http://${module.compute.alb_dns_name}"
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "availability_zones" {
  description = "使用しているAZ"
  value       = module.network.availability_zones
}

output "db_endpoint" {
  description = "RDS接続エンドポイント"
  value       = module.database.db_endpoint
}

output "dashboard_url" {
  description = "CloudWatchダッシュボードのURL"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${module.monitoring.dashboard_name}"
}
