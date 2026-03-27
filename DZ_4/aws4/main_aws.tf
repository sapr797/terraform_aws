terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "main-vpc" }
}

# Публичные подсети (для EKS и NAT)
resource "aws_subnet" "public" {
  count                   = length(var.aws_azs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = var.aws_azs[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "public-${count.index}" }
}

# Приватные подсети (для RDS)
resource "aws_subnet" "private" {
  count             = length(var.aws_azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, length(var.aws_azs) + count.index)
  availability_zone = var.aws_azs[count.index]
  tags = { Name = "private-${count.index}" }
}

# Интернет-шлюз
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "igw" }
}

# Таблица маршрутов для публичных подсетей
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (для доступа из приватных подсетей в интернет)
resource "aws_eip" "nat" {
  count  = length(var.aws_azs)
  domain = "vpc"
  tags   = { Name = "nat-eip-${count.index}" }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.aws_azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = { Name = "nat-${count.index}" }
}

# Таблица маршрутов для приватных подсетей (через NAT)
resource "aws_route_table" "private" {
  count  = length(var.aws_azs)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
  tags = { Name = "private-rt-${count.index}" }
}

resource "aws_route_table_association" "private" {
  count          = length(var.aws_azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Group для RDS (разрешить MySQL из Kubernetes и из приватных подсетей)
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL access from VPC"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "rds-sg" }
}

# Security Group для EKS (разрешить SSH и HTTP/HTTPS из интернета)
resource "aws_security_group" "eks_sg" {
  name        = "eks-sg"
  description = "Allow SSH and HTTP/HTTPS"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "eks-sg" }
}
