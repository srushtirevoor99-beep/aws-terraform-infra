resource "aws_lb" "app" {
  #checkov:skip=CKV_AWS_91:Access logging needs an S3 bucket and policy, out of scope for this demo
  #checkov:skip=CKV_AWS_150:Deletion protection would block terraform destroy, which is needed to avoid billing
  #checkov:skip=CKV2_AWS_20:HTTP only, demo project has no domain or ACM certificate
  #checkov:skip=CKV2_AWS_28:WAF has a monthly cost, out of scope for this demo
  name                       = "app-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.security_group_id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true

  tags = { Name = "app-alb" }
}

resource "aws_lb_target_group" "app" {
  #checkov:skip=CKV_AWS_378:ALB to instance traffic stays inside the VPC, demo instances have no certificates
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "app-tg" }
}

resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:HTTP only, demo project has no domain or ACM certificate
  #checkov:skip=CKV_AWS_103:HTTP listener, no TLS to configure in this demo
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}