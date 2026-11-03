resource "aws_instance" "app_server" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = false

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    repository_url = var.app_repository_url
    aws_region     = var.aws_region
    app_port       = var.app_port
    db_endpoint    = aws_db_instance.fitness_db.address
    db_name        = aws_db_instance.fitness_db.db_name
    db_secret_arn  = aws_db_instance.fitness_db.master_user_secret[0].secret_arn
    s3_bucket      = aws_s3_bucket.data.id
  })

  depends_on = [
    aws_nat_gateway.main,
    aws_iam_role_policy.app,
    aws_iam_role_policy_attachment.ssm
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-app"
  }
}
