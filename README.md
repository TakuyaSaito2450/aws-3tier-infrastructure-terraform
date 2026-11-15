## 概要
AWSの3層Web基盤(ALB/EC2 Auto Scaling/RDS)をTerraformで構築し、
**意図的に壊して復旧する過程を記録する学習用リポジトリ**です。

ベースとなる構成(雛形)を元に、自分でapply/破壊/復旧を行い、
原因の切り分けと対処を記録しています。
評価用の成果物は [aws-iac-portfolio-terraform](リンク) にまとめています。

## 構成
- ネットワーク: 2AZ、public / app / data の3層サブネット、NAT Gateway
- アプリ層: ALB + EC2（Auto Scaling）。EC2はプライベートサブネット
- データ層: RDS（MySQL）。外部への経路を持たないサブネット
- 監視: CloudWatchアラーム、SNSメール通知、ダッシュボード

## 取り組みの状況
- [ ] apply を通す
- [ ] ALB経由でページが表示されることを確認
- [ ] EC2を1台手動終了し、ASGが再作成することを確認
- [ ] nginxを停止し、ヘルスチェックの異常とアラーム通知を確認
- [ ] SGのingressをわざと削除し、疎通不可の原因特定手順を記録
- [ ] destroy で全リソースが消えることを確認
