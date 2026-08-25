output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPCのCIDR"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "public層サブネットID"
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "app層サブネットID"
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "data層サブネットID"
  value       = aws_subnet.data[*].id
}

output "availability_zones" {
  description = "使用しているAZ名"
  value       = local.azs
}
