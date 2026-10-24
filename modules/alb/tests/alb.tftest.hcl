mock_provider "aws" {}

variables {
  vpc_id            = "vpc-0123456789abcdef0"
  public_subnet_ids = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  security_group_id = "sg-0123456789abcdef0"
}

run "load_balancer_is_public_and_drops_invalid_headers" {
  command = plan

  assert {
    condition     = aws_lb.app.internal == false && aws_lb.app.load_balancer_type == "application"
    error_message = "The load balancer should be a public application load balancer"
  }

  assert {
    condition     = aws_lb.app.drop_invalid_header_fields == true
    error_message = "Invalid HTTP headers should be dropped"
  }
}

run "health_check_uses_the_root_path" {
  command = plan

  assert {
    condition     = aws_lb_target_group.app.health_check[0].path == "/" && aws_lb_target_group.app.port == 80
    error_message = "The target group should check / on port 80"
  }
}

run "alarm_fires_on_a_single_unhealthy_host" {
  command = plan

  assert {
    condition     = aws_cloudwatch_metric_alarm.unhealthy_hosts.metric_name == "UnHealthyHostCount" && aws_cloudwatch_metric_alarm.unhealthy_hosts.threshold == 1
    error_message = "The alarm should trigger at one unhealthy host"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.unhealthy_hosts.treat_missing_data == "notBreaching"
    error_message = "Missing data should not trigger the alarm"
  }
}

run "alarm_actions_are_passed_through" {
  command = plan

  variables {
    alarm_actions = ["arn:aws:sns:ap-south-1:123456789012:alerts"]
  }

  assert {
    condition     = contains(aws_cloudwatch_metric_alarm.unhealthy_hosts.alarm_actions, "arn:aws:sns:ap-south-1:123456789012:alerts")
    error_message = "The alarm should notify the configured action"
  }
}
