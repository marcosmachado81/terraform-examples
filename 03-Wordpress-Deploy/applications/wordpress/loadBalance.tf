## Bucket for access logs
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "log_bucket" {
  bucket = var.load_balance_bucket_name
  #acl
  policy        = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.load_balance_bucket_name}/${var.bucket_prefix}/AWSLogs/*",
      "Principal": {
        "AWS": [
          	"${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY
  force_destroy = true
  tags = {
    Name        = var.load_balance_bucket_name
    Environment = var.environment
    Team        = var.team
    CostCenter  =  var.costCenter

  }

  lifecycle_rule {
    id      = "log-expiration"
    enabled = "true"

    expiration {
      days = "7" # Change to var
    }
  }
}


##LOAD BALANCE CONFIGURATION
resource "aws_lb" "ALB-Wordpress" {
  name               = "ALB-Wordpress"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.SG-Wordpress.id ]
  enable_cross_zone_load_balancing = true
  subnets         = var.subnet_public_ids
  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.log_bucket.id
    prefix  = var.bucket_prefix
    enabled = true
  }

  tags = {
    Name        = "ALB-Wordpress"
    Environment = var.environment
    Team        = var.team
    CostCenter  = var.costCenter
  }

}

resource "aws_lb_target_group" "TargetGroup-Wordpress" {
  name     = "Wordpress-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 10
    path                = var.health_path
    interval            = 30
    matcher             = "200"
  }
  tags = {
    Name = "Wordpress-ALB-TG"
    Environment = var.environment
    Team        = var.team
    CostCenter  = var.costCenter
  }
}

resource "aws_lb_listener" "LBL-WebSite" {
  load_balancer_arn = aws_lb.ALB-Wordpress.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.TargetGroup-Wordpress.arn
    type             = "forward"
  }

}
#use only without autoscaling
/*
resource "aws_lb_target_group_attachment" "front_end" {
  count             = length(aws_instance.WordpressInstance)
  target_group_arn  = aws_lb_target_group.TargetGroup-Wordpress.arn
  target_id         = aws_instance.WordpressInstance[count.index].id
  port              = 80
    depends_on      = [aws_instance.WordpressInstance]
}
*/
