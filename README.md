## 概要
AWSの3層Web基盤（ALB / EC2 Auto Scaling / RDS）をTerraformで**自分で書いて積み上げる**学習用リポジトリです。
構築・障害再現・復旧の過程を記録します。

当初はテンプレートを元に始めましたが、中身を読み取れなかったため、
基礎から1ステップずつ自作する方針に切り替えました。
元のテンプレートは `template-original` ブランチに保存しています（参照用）。
評価用の成果物は [aws-iac-portfolio-terraform](リンク) にまとめています。

## 目標とする構成
- ネットワーク: 2AZ、public / app / data の3層サブネット、NAT Gateway
- アプリ層: ALB + EC2（Auto Scaling）。EC2はプライベートサブネット
- データ層: RDS（MySQL）
- 監視: CloudWatchアラーム、SNSメール通知

## 進捗
- [x] テンプレートを退避し、自作に切り替え
- [ ] VPC・サブネット・NAT・ルートテーブル
- [ ] セキュリティグループ
- [ ] ALB
- [ ] Auto Scaling
- [ ] RDS
- [ ] 監視
