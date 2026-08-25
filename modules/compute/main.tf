# ============================================================
# compute モジュール
#   ALB / Target Group / Launch Template / Auto Scaling Group
# ------------------------------------------------------------
# 設計判断:
#   - EC2は個別リソースではなくASG配下に置く。台数変更・AZ障害時の
#     再作成をコード側で吸収するため。
#   - AMIはハードコードせず SSM Public Parameter から取得。
#     リージョン差異とAMI更新に追従できる。
#   - ヘルスチェックタイプは ELB。プロセス停止をASGが検知できる。
# ============================================================

locals {
  common_tags = merge(var.tags, { Module = "compute" })
}

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ------------------------------------------------------------
# ALB
# ------------------------------------------------------------
resource "aws_lb" "this" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  idle_timeout               = 60
  drop_invalid_header_fields = true

  tags = merge(local.common_tags, { Name = "${var.name_prefix}-alb" })
}

resource "aws_lb_target_group" "app" {
  name     = "${var.name_prefix}-tg-app"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, { Name = "${var.name_prefix}-tg-app" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = local.common_tags
}

# ------------------------------------------------------------
# Launch Template
# ------------------------------------------------------------
resource "aws_launch_template" "app" {
  name_prefix   = "${var.name_prefix}-lt-app-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.app_sg_id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 必須化
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = var.detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    app_port = var.app_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${var.name_prefix}-app" })
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------
# Auto Scaling Group
# ------------------------------------------------------------
resource "aws_autoscaling_group" "app" {
  name                      = "${var.name_prefix}-asg-app"
  vpc_zone_identifier       = var.app_subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 120
  target_group_arns         = [aws_lb_target_group.app.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(local.common_tags, { Name = "${var.name_prefix}-app" })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# CPU使用率に基づくターゲット追跡スケーリング
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name_prefix}-asp-cpu"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_value
  }
}
