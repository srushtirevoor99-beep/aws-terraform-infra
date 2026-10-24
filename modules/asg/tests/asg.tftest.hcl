mock_provider "aws" {
  mock_data "aws_ami" {
    defaults = {
      id = "ami-0123456789abcdef0"
    }
  }
}

variables {
  subnet_ids        = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
  target_group_arn  = "arn:aws:elasticloadbalancing:ap-south-1:123456789012:targetgroup/app-tg/0123456789abcdef"
  security_group_id = "sg-0123456789abcdef0"
}

run "instances_require_imdsv2" {
  command = plan

  assert {
    condition     = aws_launch_template.app.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be required on every instance"
  }

  assert {
    condition     = aws_launch_template.app.metadata_options[0].http_put_response_hop_limit == 1
    error_message = "The metadata hop limit should stay at 1 so containers cannot reach it"
  }
}

run "default_capacity_is_two_to_four_instances" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.app.min_size == 2 && aws_autoscaling_group.app.desired_capacity == 2 && aws_autoscaling_group.app.max_size == 4
    error_message = "The group should default to 2 minimum, 2 desired and 4 maximum instances"
  }

  assert {
    condition     = aws_autoscaling_group.app.health_check_type == "ELB"
    error_message = "The group should replace instances that fail load balancer health checks"
  }
}

run "scales_on_average_cpu_at_fifty_percent" {
  command = plan

  assert {
    condition     = aws_autoscaling_policy.cpu.target_tracking_configuration[0].target_value == 50
    error_message = "The CPU target should be 50 percent"
  }

  assert {
    condition     = aws_autoscaling_policy.cpu.target_tracking_configuration[0].predefined_metric_specification[0].predefined_metric_type == "ASGAverageCPUUtilization"
    error_message = "Scaling should track average CPU utilization"
  }
}

run "capacity_can_be_overridden" {
  command = plan

  variables {
    max_size = 6
  }

  assert {
    condition     = aws_autoscaling_group.app.max_size == 6
    error_message = "The max_size variable should change the group size"
  }
}
