output "alb_sg_id" {
  description = "ALB用SGのID"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "app層用SGのID"
  value       = aws_security_group.app.id
}

output "data_sg_id" {
  description = "data層用SGのID"
  value       = aws_security_group.data.id
}

output "app_instance_profile_name" {
  description = "EC2にアタッチするインスタンスプロファイル名"
  value       = aws_iam_instance_profile.app.name
}
