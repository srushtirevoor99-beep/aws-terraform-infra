mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
    }
  }
}

run "uses_the_default_cidr_ranges" {
  command = plan

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "The VPC should default to 10.0.0.0/16"
  }

  assert {
    condition     = aws_subnet.public_a.cidr_block == "10.0.1.0/24" && aws_subnet.public_b.cidr_block == "10.0.2.0/24"
    error_message = "Public subnets should be 10.0.1.0/24 and 10.0.2.0/24"
  }

  assert {
    condition     = aws_subnet.private_a.cidr_block == "10.0.11.0/24" && aws_subnet.private_b.cidr_block == "10.0.12.0/24"
    error_message = "Private subnets should be 10.0.11.0/24 and 10.0.12.0/24"
  }
}

run "spreads_subnets_across_two_availability_zones" {
  command = plan

  assert {
    condition     = aws_subnet.public_a.availability_zone != aws_subnet.public_b.availability_zone
    error_message = "Public subnets must be in different availability zones"
  }

  assert {
    condition     = aws_subnet.private_a.availability_zone != aws_subnet.private_b.availability_zone
    error_message = "Private subnets must be in different availability zones"
  }
}

run "subnets_do_not_hand_out_public_ips_by_default" {
  command = plan

  assert {
    condition     = aws_subnet.public_a.map_public_ip_on_launch == false && aws_subnet.public_b.map_public_ip_on_launch == false
    error_message = "Public IPs come from the launch template, not from the subnet"
  }
}

run "public_route_sends_internet_traffic_to_the_gateway" {
  command = plan

  assert {
    condition     = aws_route.public_internet.destination_cidr_block == "0.0.0.0/0"
    error_message = "The public route table needs a default route to the internet gateway"
  }
}

run "cidr_ranges_can_be_overridden" {
  command = plan

  variables {
    vpc_cidr = "172.16.0.0/16"
  }

  assert {
    condition     = aws_vpc.main.cidr_block == "172.16.0.0/16"
    error_message = "The vpc_cidr variable should change the VPC range"
  }
}
