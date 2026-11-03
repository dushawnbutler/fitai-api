resource "aws_lb" "internal" {
  name               = "${var.project_name}-${var.environment}-internal"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.private[*].id
}

resource "aws_lb_target_group" "internal_app" {
  name        = "${var.project_name}-${var.environment}-internal"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled = true
    path    = "/health"
    matcher = "200"
  }
}

resource "aws_lb_target_group_attachment" "internal_app" {
  target_group_arn = aws_lb_target_group.internal_app.arn
  target_id        = aws_instance.app_server.id
  port             = var.app_port
}

resource "aws_lb_listener" "internal_http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_app.arn
  }
}
