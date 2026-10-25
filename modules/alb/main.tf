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

# Fires when a target has failed health checks for three minutes in a row
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "app-unhealthy-hosts"
  alarm_description   = "At least one instance behind the load balancer is failing health checks"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  period              = 60
  evaluation_periods  = 3
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  tags = { Name = "app-unhealthy-hosts" }
}
