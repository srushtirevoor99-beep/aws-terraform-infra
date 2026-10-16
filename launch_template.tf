data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "app-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable --now docker
    mkdir -p /opt/web
    echo "<h1>Hello from $(hostname)</h1>" > /opt/web/index.html
    docker run -d --restart always -p 80:80 \
      -v /opt/web:/usr/share/nginx/html:ro nginx:latest
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "app-instance" }
  }

  tags = { Name = "app-launch-template" }
}
