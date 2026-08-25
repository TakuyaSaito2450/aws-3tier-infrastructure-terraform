# ============================================================
# network モジュール
#   VPC / 3層サブネット / IGW / NAT / ルートテーブル
# ------------------------------------------------------------
# 設計判断:
#   - AZは2つ。ALB・RDS Multi-AZ の最小要件が2AZのため。
#   - NAT Gateway は既定で1台(単一AZ)。AZごとに置くと月額が約2倍に
#     なるため検証環境ではコストを優先。本番相当にする場合は
#     single_nat_gateway = false に切り替える。
#   - data層は外部通信なし(ローカルルートのみ)。RDSに不要な経路を
#     持たせないための分離。
# ============================================================

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs         = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  common_tags = merge(var.tags, { Module = "network" })
  nat_count   = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : var.az_count) : 0
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name_prefix}-igw" })
}

# ------------------------------------------------------------
# サブネット (public / app / data)
#   cidrsubnet(/16, 8, n) で /24 を切り出す
#   public: .0 .1 / app: .10 .11 / data: .20 .21
# ------------------------------------------------------------
resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public-${local.azs[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "app" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = local.azs[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-app-${local.azs[count.index]}"
    Tier = "app"
  })
}

resource "aws_subnet" "data" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 20)
  availability_zone = local.azs[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-data-${local.azs[count.index]}"
    Tier = "data"
  })
}

# ------------------------------------------------------------
# NAT Gateway
# ------------------------------------------------------------
resource "aws_eip" "nat" {
  count = local.nat_count

  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${var.name_prefix}-nat-eip-${count.index + 1}" })
}

resource "aws_nat_gateway" "this" {
  count = local.nat_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags       = merge(local.common_tags, { Name = "${var.name_prefix}-natgw-${count.index + 1}" })
  depends_on = [aws_internet_gateway.this]
}

# ------------------------------------------------------------
# ルートテーブル
# ------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name_prefix}-rtb-public" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "app" {
  count = var.az_count

  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name_prefix}-rtb-app-${local.azs[count.index]}" })
}

resource "aws_route" "app_nat" {
  count = var.enable_nat_gateway ? var.az_count : 0

  route_table_id         = aws_route_table.app[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
}

resource "aws_route_table_association" "app" {
  count = var.az_count

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.common_tags, { Name = "${var.name_prefix}-rtb-data" })
}

resource "aws_route_table_association" "data" {
  count = var.az_count

  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data.id
}
