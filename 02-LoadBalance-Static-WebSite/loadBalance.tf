## Bucket for access logs
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "log_bucket" {
  bucket = local.bucket_name
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
      "Resource": "arn:aws:s3:::${local.bucket_name}/${local.bucket_prefix}/AWSLogs/*",
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
    Name        = "loadbalance-staticwebsite-0394902"
    Environment = local.env
  }

  #tags            = "${module.label.tags}"
  lifecycle_rule {
    id      = "log-expiration"
    enabled = "true"

    expiration {
      days = "7" # Change to var
    }

    #tags  = "${module.label.tags}"
  }
}


##LOAD BALANCE CONFIGURATION#################################################################
resource "aws_lb" "ALB-WebSite" {
  name               = "ALB-WebSite"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.SG-WebServer.id ]
  enable_cross_zone_load_balancing = true
  subnets            = [
    for snet in aws_subnet.public:
      snet.id
  ]
  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.log_bucket.id
    prefix  = local.bucket_prefix
    enabled = true
  }

  tags = {
    Name        = "ALB-WebSite"
    Environment = local.env
  }

  #depends_on = [ aws_s3_bucket.log_bucket ]
}

resource "aws_lb_target_group" "TG-WebSite" {
  name     = "WebSite-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.principal.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 10
    path                = "/health.html"
    interval            = 30
    matcher = "200"
  }
  tags = {
    Name = "WebSite-ALB-TG"
    Environment = local.env
  }
}

resource "aws_lb_listener" "LBL-WebSite" {
  load_balancer_arn = aws_lb.ALB-WebSite.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.TG-WebSite.arn
    type             = "forward"
  }

}
#use only without autoscaling
resource "aws_lb_target_group_attachment" "front_end" {
  count    = length(aws_instance.WebServer)
  target_group_arn = aws_lb_target_group.TG-WebSite.arn
  target_id = aws_instance.WebServer[count.index].id
  port             = 80
    depends_on = [aws_instance.WebServer]
}
