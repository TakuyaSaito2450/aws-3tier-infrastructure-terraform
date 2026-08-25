output "alb_dns_name" {
  description = "ALBのDNS名 (動作確認用URL)"
  value       = aws_lb.this.dns_name
}

output "alb_arn_suffix" {
  description = "CloudWatchメトリクス用のALB識別子"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "CloudWatchメトリクス用のTG識別子"
  value       = aws_lb_target_group.app.arn_suffix
}

output "asg_name" {
  description = "Auto Scaling Group名"
  value       = aws_autoscaling_group.app.name
}
