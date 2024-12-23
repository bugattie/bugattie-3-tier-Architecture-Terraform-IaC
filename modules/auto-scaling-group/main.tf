resource "aws_launch_template" "launch_template" {
  name_prefix = var.launch_template_name
  image_id               = var.ami_id
  instance_type          = "t2.micro"
  user_data              = base64encode(file("user-data.sh"))
  vpc_security_group_ids = var.security_groups

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = var.launch_template_name
    })
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                = var.asg_name
  desired_capacity    = 1
  min_size            = 1
  max_size            = 4
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }
}