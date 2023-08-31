resource "aws_launch_template" "template" {
  name = local.name

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 8
      volume_type           = "gp3"
    }
  }

  image_id = local.ami_id

  key_name = "teraoka"

  iam_instance_profile {
    arn = aws_iam_instance_profile.profile.arn
  }

  # `associate_public_ip_address = true` が不要なら
  # network_interfaces block は不要で
  # ここで security group を指定する
  #vpc_security_group_ids = [aws_security_group.server.id]

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.server.id]
  }

  user_data = filebase64("${path.module}/user-data.sh")

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name      = local.name
      owner     = "teraoka"
      terraform = "spot-asg-proxy"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name      = local.name
      owner     = "teraoka"
      terraform = "spot-asg-proxy"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  max_size                  = 1
  min_size                  = 1
  name                      = local.name
  vpc_zone_identifier       = module.vpc.public_subnets
  health_check_grace_period = 300
  health_check_type         = "ELB"

  mixed_instances_policy {
    instances_distribution {
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.template.id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = toset(local.instance_types)
        content {
          instance_type = override.value
        }
      }
    }
  }
}
