output "sns_topic_arn" {
  description = "アラート通知用SNSトピックのARN"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "CloudWatchダッシュボード名"
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}
