terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ------------------------------------------------------------
# VPC
# ------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# ------------------------------------------------------------
# Subnets
# ------------------------------------------------------------
resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public-subnet2"
  }
}

resource "aws_subnet" "private_app1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_app1_subnet"
  }
}

resource "aws_subnet" "private_app2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_app2_subnet"
  }
}

resource "aws_subnet" "private_db1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_db1_subnet"
  }
}

resource "aws_subnet" "private_db2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_db2_subnet"
  }
}

# ------------------------------------------------------------
# NAT Gateway
# ------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-gateway-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public1.id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "main-nat-gateway"
  }
}

# ------------------------------------------------------------
# Route tables
# ------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private_route_table"
  }
}

# ------------------------------------------------------------
# Route table associations
# ------------------------------------------------------------
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app1" {
  subnet_id      = aws_subnet.private_app1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_app2" {
  subnet_id      = aws_subnet.private_app2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db1" {
  subnet_id      = aws_subnet.private_db1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_db2" {
  subnet_id      = aws_subnet.private_db2.id
  route_table_id = aws_route_table.private.id
}

# ------------------------------------------------------------
# ALB
# ------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "security-group-alb"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP to the app instances"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"]
  }

  tags = {
    Name = "security-group-alb"
  }
}

# ------------------------------------------------------------
# Target Group
# ------------------------------------------------------------
resource "aws_lb_target_group" "http" {
  name        = "tf-example-lb-alb-tg"
  target_type = "alb"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
}