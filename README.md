# AWS 3層Web基盤 / Terraform IaC

ALB + EC2(Auto Scaling) + RDS の3層構成を Terraform でコード化し、監視・通知までを含めて一括で構築/破棄できるようにしたものです。

運用保守で扱ってきた構成を、手作業ではなくコードで再現できる形に置き換えることを目的に作成しました。

---

## 構成図

```
                          Internet
                              |
                    [ Internet Gateway ]
                              |
        ┌─────────────────────┴─────────────────────┐
        │            public subnet (2AZ)             │
        │   ┌──────────────────────────────────┐     │
        │   │        Application LB            │     │
        │   └──────────────┬───────────────────┘     │
        │        [ NAT Gateway x1 ]                  │
        └─────────────────────┬─────────────────────┘
                              │
        ┌─────────────────────┴─────────────────────┐
        │             app subnet (2AZ)               │
        │   ┌──────────┐          ┌──────────┐      │
        │   │  EC2(a)  │          │  EC2(c)  │      │  Auto Scaling Group
        │   │  nginx   │          │  nginx   │      │  min2 / max4
        │   └──────────┘          └──────────┘      │
        └─────────────────────┬─────────────────────┘
                              │
        ┌─────────────────────┴─────────────────────┐
        │            data subnet (2AZ)               │
        │        ┌──────────────────────┐            │
        │        │   RDS for MySQL      │            │
        │        └──────────────────────┘            │
        └────────────────────────────────────────────┘

        監視: CloudWatch Alarm → SNS → メール通知
```

| 項目 | 値 |
|---|---|
| リージョン | ap-northeast-1 |
| VPC CIDR | 10.0.0.0/16 |
| AZ数 | 2 |
| サブネット | public / app / data の3層 × 2AZ = 6 |
| Terraform | >= 1.6 |
| AWS Provider | ~> 5.0 |

---

## ディレクトリ構成

```
.
├── envs/
│   └── dev/                    # 環境ごとのルートモジュール
│       ├── main.tf             #   モジュールの組み立て
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── backend.tf          #   リモートstate(移行手順つき)
│       └── terraform.tfvars.example
└── modules/
    ├── network/                # VPC / サブネット / NAT / ルート
    ├── security/               # SG / IAMロール
    ├── compute/                # ALB / LaunchTemplate / ASG
    ├── database/               # RDS / サブネットグループ
    └── monitoring/             # SNS / アラーム / ダッシュボード
```

環境差分は `terraform.tfvars` のみで表現し、`main.tf` は dev/stg/prd で共通にしています。`envs/prd/` を追加する場合も、tfvars を変えるだけで同じ構成を再現できます。

---

## 設計上の判断

コードそのものより、なぜその構成にしたかを残すことを重視しました。

### NAT Gatewayを1台に集約した

NAT Gateway は 1 台あたり月額約 5,000 円（時間課金＋データ処理料）かかります。AZ ごとに配置すれば片方の AZ 障害時も app 層からの外向き通信を維持できますが、この環境で NAT を使うのは OS アップデートと SSM 接続のみで、停止しても利用者影響は出ません。

そのため **可用性よりコストを優先し、既定を1台**としました。本番相当の構成を示す際は `single_nat_gateway = false` で AZ ごとの配置に切り替えられるよう変数化しています。

### RDS Multi-AZ を変数で切り替え可能にした

Multi-AZ はスタンバイ機の分だけ料金が倍になります。学習用途では `false`、可用性要件を説明する場面では `true` と、同じコードで両方を示せるようにしました。

一方で **DB Subnet Group は常に2AZ構成**にしています。ここを1AZで作ると、後から Multi-AZ に変更する際にサブネットグループの作り直しが必要になり、ダウンタイムが発生するためです。

### SGの参照をCIDRではなくSG-IDにした

app 層の ingress は `10.0.10.0/24` のようなCIDRではなく、ALB の SG ID を参照しています。サブネット構成を変更しても許可設定が壊れず、また「ALB からのみ受ける」という意図がコード上で読み取れるためです。

### SSHポートを開けていない

22番を一切開けず、運用アクセスは SSM Session Manager に寄せました。踏み台サーバの構築・維持が不要になり、アクセス記録も CloudTrail に残ります。IAM ロールには `AmazonSSMManagedInstanceCore` と CloudWatch Agent 用の2つのみを付与しています。

### DBパスワードをコードに置かない

`manage_master_user_password = true` を使い、パスワードの生成と保管を Secrets Manager に委ねています。tfvars にも state にも平文が残りません。

### アラームを4つに絞った

CloudWatch のメトリクスを網羅的に監視すると通知過多になり、結果として誰も見なくなります。前職で JP1 の監視設計に携わった際、アラート疲れで重要な通知が埋もれる状況を見てきたため、**利用者影響が出る指標だけ**に絞りました。

| アラーム | 閾値 | 意図 |
|---|---|---|
| ALB 5xx | 5分間で5件超 | ユーザーがエラー画面を見ている |
| UnHealthyHostCount | 1台以上が2分継続 | 縮退運転に入っている |
| RDS CPU | 80%が10分継続 | クエリ増加・スロークエリの兆候 |
| RDS 空き容量 | 2GiB未満 | 停止に至る前の予兆 |

---

## 使い方

### 前提

- AWS CLI の認証情報が設定済みであること
- Terraform 1.6 以上

### 手順

```bash
cd envs/dev

# tfvars を用意（自宅IPなどを含むためGit管理外）
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars

terraform init
terraform fmt -recursive -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

### 動作確認

```bash
# ALBのURLを取得
terraform output alb_url

# アクセスするとインスタンスIDとAZが表示される
curl $(terraform output -raw alb_url)
```

リロードすると表示される Instance ID が切り替わり、2台に分散していることを確認できます。

### 冗長性の確認

```bash
# 片方のインスタンスを手動で終了させる
aws autoscaling terminate-instance-in-auto-scaling-group \
  --instance-id <id> --should-decrement-desired-capacity

# ALB経由のアクセスが継続すること、
# 数分後にASGが自動で1台を再作成することを確認
```

### 破棄

```bash
terraform destroy
```

RDS の `skip_final_snapshot` は dev では `true` にしているため、そのまま削除できます。

---

## 概算コスト（ap-northeast-1 / 月額）

| リソース | 概算 |
|---|---|
| NAT Gateway × 1 | 約 5,000 円 |
| ALB × 1 | 約 2,800 円 |
| EC2 t3.micro × 2 | 約 3,000 円 |
| RDS db.t3.micro（Single-AZ） | 約 2,500 円 |
| EBS / データ転送 / その他 | 約 1,000 円 |
| **合計** | **約 14,000 円** |

常時起動させると学習コストとして重いため、**検証時のみ apply し、確認後は destroy する運用**を前提にしています。1回あたり数時間の起動なら数百円程度に収まります。

料金は変動するため、実行前に AWS Pricing Calculator で確認してください。

---

## 苦労した点

（実際に構築した際の記録をここに追記してください。以下は書き方の例です）

### 例1: ALBのヘルスチェックが通らない

Target が `unhealthy` のままとなり、原因の切り分けに時間を要した。SG の ingress は許可済みだったが、ALB 側の **egress** を app 層の SG に向けて明示していなかったため通信が成立していなかった。

SG は ingress だけでなく egress も双方向で確認する必要があると理解した。OCI の NSG で通信要件と設計書を突き合わせた作業と同じ考え方で、送信元・宛先の両側から見る習慣が役に立った。

### 例2: （ここに実際の事象を記載）

---

## 今後の拡張

- [ ] HTTPS化（ACM証明書 + Route 53 + リスナーのリダイレクト）
- [ ] GitHub Actions による `fmt` / `validate` / `plan` の自動実行
- [ ] tflint / trivy によるコード検査の組み込み
- [ ] リモートstate（S3 + DynamoDB）への移行
- [ ] 同一構成の OCI 版（Terraform OCI Provider）

---

## 作成者

斎藤 卓也 / インフラエンジニア
AWS Certified Solutions Architect – Associate (SAA-C03), LPIC-1, LPIC-2 (201)
