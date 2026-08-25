# ============================================================
# monitoring モジュール
#   SNSトピック / CloudWatchアラーム / ダッシュボード
# ------------------------------------------------------------
# 設計判断:
#   - 「作って終わり」にせず、運用に必要な通知経路まで含める。
#     JP1で監視設計をしていた経験をAWSに置き換えた構成。
#   - アラームは "利用者影響が出る指標" に絞る。
#     ALB 5xx / TargetGroup 異常ホスト数 / RDS CPU・空き容量。
#     メトリクスを網羅すると通知過多になり運用が形骸化するため。
# ============================================================

locals {
  common_tags = merge(var.tags, { Module = "monitoring" })
}

resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-topic-alerts"
  tags = merge(local.common_tags, { Name = "${var.name_prefix}-topic-alerts" })
}

resource "aws_sns_topic_subscription" "email" {
  count = var.alert_email == null ? 0 : 1

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ------------------------------------------------------------
# ALB: 5xxエラー
# ------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name_prefix}-alb-5xx"
  alarm_description   = "ALBが返す5xxが閾値を超過"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.alb_5xx_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

# ------------------------------------------------------------
# TargetGroup: 異常ホスト検知
# ------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.name_prefix}-tg-unhealthy"
  alarm_description   = "ヘルスチェック異常のターゲットが存在"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

# ------------------------------------------------------------
# RDS: CPU / 空きストレージ
# ------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  alarm_description   = "RDSのCPU使用率が継続して高い"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.rds_cpu_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.name_prefix}-rds-storage-low"
  alarm_description   = "RDSの空きストレージが閾値を下回った"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.rds_free_storage_threshold_bytes
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  tags          = local.common_tags
}

# ------------------------------------------------------------
# ダッシュボード
# ------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB リクエスト数 / 5xx"
          region = var.region
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum" }],
            [".", "HTTPCode_ELB_5XX_Count", ".", ".", { stat = "Sum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ASG CPU使用率"
          region = var.region
          view   = "timeSeries"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name, { stat = "Average" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "RDS CPU / 接続数"
          region = var.region
          view   = "timeSeries"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_identifier, { stat = "Average" }],
            [".", "DatabaseConnections", ".", ".", { stat = "Average" }]
          ]
        }
      }
    ]
  })
}
