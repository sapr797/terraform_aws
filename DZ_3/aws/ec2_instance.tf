# AMI для Amazon Linux 2 (последняя)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Bootstrap-скрипт: устанавливает Apache, создаёт index.html и загружает в S3
locals {
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    cd /var/www/html
    echo "<html><h1>My cool web-server from EC2</h1></html>" > index.html
    # Устанавливаем AWS CLI (уже может быть предустановлен)
    # Загружаем файл в S3
    aws s3 cp index.html s3://${aws_s3_bucket.web_bucket.bucket}/index.html
  EOF
}

# Security Group для EC2 (SSH, HTTP)
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-web-sg"
  description = "Allow SSH and HTTP"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-web-sg"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id   # предполагается, что публичная подсеть уже создана
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  user_data              = base64encode(local.user_data)

  tags = {
    Name = "web-server"
  }
}
