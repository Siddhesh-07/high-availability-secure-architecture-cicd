# ==================== LAUNCH TEMPLATE (Blueprint for EC2 instances) ====================

resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              exec > >(tee /var/log/user-data.log)
              exec 2>&1
              
              echo "Starting user data script..."
              
              yum update -y
              yum install -y docker
              yum install -y docker-compose
              
              systemctl start docker
              systemctl enable docker
              
              # Add ec2-user to docker group
              usermod -a -G docker ec2-user
              
              echo "Docker and Docker Compose installed"
              
              yum install -y amazon-ssm-agent
              systemctl start amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              
              # Add ssm-user to docker group
              usermod -a -G docker ssm-user
              
              echo "SSM agent installed and started"
              echo "User data script completed successfully"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-instance"
    }
  }

  tags = {
    Name = "${var.project_name}-lt"
  }


  lifecycle {
    create_before_destroy = true
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

