resource "aws_lb" "main" {
  name               = "ads-platform-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

resource "aws_lb_target_group" "app" {
  name        = "ads-platform-tg"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"

  vpc_id = aws_vpc.main.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn

  port     = 443
  protocol = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-2016-08"

  certificate_arn = aws_acm_certificate.main.arn

  depends_on = [aws_acm_certificate_validation.main]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_acm_certificate" "main" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn

  timeouts {
    create = "5m"
  }
}

output "acm_certificate_validation_records" {
  value = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  description = "Add these CNAME records to Cloudflare to validate the ACM certificate"
}