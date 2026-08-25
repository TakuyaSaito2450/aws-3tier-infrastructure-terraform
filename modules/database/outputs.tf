output "db_endpoint" {
  description = "RDSの接続エンドポイント"
  value       = aws_db_instance.this.address
}

output "db_identifier" {
  description = "RDSインスタンス識別子"
  value       = aws_db_instance.this.identifier
}

output "db_secret_arn" {
  description = "マスターパスワードが格納されたSecrets ManagerのARN"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive   = true
}
