# ============================================================
# security モジュール
#   セキュリティグループ / EC2用IAMロール
# ------------------------------------------------------------
# 設計判断:
#   - SGは層ごとに分離し、参照はCIDRではなくSG-IDで行う。
#     (IP変更の影響を受けず、通信元が構成図として読み取れる)
#   - EC2へのSSHは開けない。運用アクセスは SSM Session Manager に
#     寄せることで、22番の解放と踏み台の運用を不要にする。
# ============================================================

locals {
  common_tags = merge(var.tags, { Module = "security" })
}

# ------------------------------------------------------------
# ALB: インターネットから 80/443 のみ受ける
# ------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-sg-alb"
  description = "ALB ingress from internet"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name_prefix}-sg-alb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from allowed CIDR"
  cidr_ipv4         = var.ingress_cidr
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to app tier"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

# ------------------------------------------------------------
# app: ALBからのみ受ける
# ------------------------------------------------------------
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-sg-app"
  description = "App tier, ingress from ALB only"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name_prefix}-sg-app" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "From ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

# yum/dnf・SSMエンドポイントへの到達に必要
resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  description       = "Outbound via NAT (package update, SSM)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ------------------------------------------------------------
# data: appからのみ 3306 を受ける。egressなし。
# ------------------------------------------------------------
resource "aws_security_group" "data" {
  name        = "${var.name_prefix}-sg-data"
  description = "RDS, ingress from app tier only"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name_prefix}-sg-data" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "data_from_app" {
  security_group_id            = aws_security_group.data.id
  description                  = "MySQL from app tier"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

# ------------------------------------------------------------
# EC2用IAMロール
#   SSM接続 + CloudWatch Agent の最小構成。
#   インラインで s3:* のような広い権限は付けない。
# ------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.name_prefix}-role-app"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name_prefix}-profile-app"
  role = aws_iam_role.app.name
  tags = local.common_tags
}
