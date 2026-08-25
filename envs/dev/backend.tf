# ============================================================
# リモートステート
# ------------------------------------------------------------
# 初回はローカルstateで apply し、S3バケットとDynamoDBテーブルを
# 手動または別スタックで用意してから、このブロックを有効化して
# `terraform init -migrate-state` を実行する。
#
# state をローカルに置いたままだと、複数端末での作業や
# チーム運用ができないため、実務ではリモート化が前提。
# ============================================================

# terraform {
#   backend "s3" {
#     bucket         = "CHANGEME-tfstate-<accountid>"
#     key            = "3tier/dev/terraform.tfstate"
#     region         = "ap-northeast-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }
