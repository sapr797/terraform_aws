# Subnet group для RDS (в приватных подсетях)
resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags       = { Name = "rds-subnet-group" }
}

# Параметр группы для MySQL 8.0
resource "aws_db_parameter_group" "mysql" {
  family = "mysql8.0"
  name   = "mysql-params"
  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
}

# Кластер RDS MySQL с Multi-AZ и резервным копированием на 7 дней
resource "aws_db_instance" "rds" {
  identifier                 = "mysql-cluster"
  engine                     = "mysql"
  engine_version             = "8.0"
  instance_class             = "db.t3.medium"
  allocated_storage          = 20
  storage_encrypted          = true
  multi_az                   = true
  db_subnet_group_name       = aws_db_subnet_group.rds.name
  vpc_security_group_ids     = [aws_security_group.rds_sg.id]
  username                   = var.db_username
  password                   = var.db_password
  db_name                    = var.db_name
  backup_retention_period    = 7
  backup_window              = "23:00-23:30"
  maintenance_window         = "sun:04:00-sun:05:00"
  skip_final_snapshot        = true
  deletion_protection        = false
  parameter_group_name       = aws_db_parameter_group.mysql.name
  tags = { Name = "mysql-cluster" }
}

# Две реплики чтения в разных AZ
resource "aws_db_instance" "replica" {
  count                = 2
  identifier           = "mysql-replica-${count.index}"
  replicate_source_db  = aws_db_instance.rds.id
  instance_class       = "db.t3.medium"
  availability_zone    = var.aws_azs[count.index % length(var.aws_azs)]
  backup_retention_period = 0
  skip_final_snapshot  = true
  tags = { Name = "mysql-replica-${count.index}" }
}

output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "replica_endpoints" {
  value = aws_db_instance.replica[*].endpoint
}
