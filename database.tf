resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnets"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "fitness_db" {
  identifier                  = "${var.project_name}-${var.environment}-db"
  engine                      = "postgres"
  instance_class              = "db.t3.micro"
  db_name                     = "fitai"
  username                    = "fitaiadmin"
  manage_master_user_password = true
  allocated_storage           = 20
  storage_type                = "gp3"
  storage_encrypted           = true
  db_subnet_group_name        = aws_db_subnet_group.main.name
  vpc_security_group_ids      = [aws_security_group.database.id]
  publicly_accessible         = false
  backup_retention_period     = 7
  auto_minor_version_upgrade  = true

  # Development teardown setting. Review before using with valuable data.
  skip_final_snapshot = true
  deletion_protection = false
}
