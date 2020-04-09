###
##AUtoscaling Configuration##################################################################
####
resource "aws_launch_configuration" "LC-FrontEnd" {
  name_prefix            = "Auto-"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  security_groups        = [ aws_security_group.SG-Wordpress.id ]
  key_name               = var.key_name
  associate_public_ip_address = true
  user_data              = templatefile("${path.module}/as_deploy.tmpl",{
                          BUCKETADDRESS = var.wp_content_bucket_name,
                          SECRETACCSKEY = aws_iam_access_key.user_s3.secret, //var.s3_secret_access_key,
                          ACCSKEY       = aws_iam_access_key.user_s3.id, //var.s3_access_key,
                          MOUNTPOINT    = var.wordpress_wp_content,
                          GOOFYSv       = "v0.23.1",
                          EFSID         = aws_efs_file_system.wordpress_code.id
                          })
  lifecycle {
    create_before_destroy = true
  }

}
#padding_policy
resource "aws_autoscaling_policy" "ASP-FrontEndUP" {
  name                   = "Wordpress-Policy-UP"
  scaling_adjustment     = var.auto_scale_capacityUP
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.auto_scale_cooldown
  autoscaling_group_name = aws_autoscaling_group.ASG-FrontEnd.name
}

resource "aws_autoscaling_policy" "ASP-FrontEndDOWN" {
  name                   = "Wordpress-Policy-DOWN"
  scaling_adjustment     = var.auto_scale_capacityDOWN
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.auto_scale_cooldown
  autoscaling_group_name = aws_autoscaling_group.ASG-FrontEnd.name
}

resource "aws_cloudwatch_metric_alarm" "FrontEnd-CPU-Alarm-DOWN" {
  alarm_name          = "Wordpress-CPU-Alarm-DOWN"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.as_metric_down_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.as_metric_down_period
  statistic           = "Average"
  threshold           = var. as_metric_down_threshold

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.ASG-FrontEnd.name}"
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.ASP-FrontEndDOWN.arn ]
}

resource "aws_cloudwatch_metric_alarm" "FrontEnd-CPU-Alarm-UP" {
  alarm_name          = "Wordpress-CPU-Alarm-UP"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.as_metric_up_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.as_metric_up_period
  statistic           = "Average"
  threshold           = var.as_metric_up_threshold

  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.ASG-FrontEnd.name}"
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [ aws_autoscaling_policy.ASP-FrontEndUP.arn ]
}


## Creating AutoScaling Group
resource "aws_autoscaling_group" "ASG-FrontEnd" {
  name                  = "Wordpress-ASG"
  launch_configuration  = aws_launch_configuration.LC-FrontEnd.id
  vpc_zone_identifier   = var.subnet_public_ids
  #vpc_zone_identifier   = [ for sub in aws_subnet.public:
  #                          sub.id ]
  min_size              = var.auto_scaling_min_size
  desired_capacity      = var.auto_scaling_desired_capacity
  max_size              = var.auto_scaling_max_size
  target_group_arns     = [aws_lb_target_group.TargetGroup-Wordpress.arn]
  health_check_type     = "ELB"
  default_cooldown      = var.auto_scale_cooldown

  depends_on = [ aws_instance.WordpressInstance ]

  tag {
    key = "Name"
    value = "Auto-Wordpress-ASG"
    propagate_at_launch = true
  }
}
