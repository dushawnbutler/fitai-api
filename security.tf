resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-"
  description = "Load balancer security group"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-"
  description = "API security group"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-db-"
  description = "Database security group"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group" "api_gateway_link" {
  name_prefix = "${var.project_name}-apigw-link-"
  description = "VPC link access to load balancer"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_api_gateway" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.api_gateway_link.id
  description                  = "HTTP from API Gateway VPC link"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.app.id
  description                  = "Forward requests and health checks to API"
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "api_gateway_to_alb" {
  security_group_id            = aws_security_group.api_gateway_link.id
  referenced_security_group_id = aws_security_group.alb.id
  description                  = "VPC link to load balancer HTTP listener"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  description                  = "API traffic from load balancer"
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_outbound" {
  security_group_id = aws_security_group.app.id
  description       = "App setup, AWS APIs, and database access"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "database_from_app" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.app.id
  description                  = "PostgreSQL from API"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
