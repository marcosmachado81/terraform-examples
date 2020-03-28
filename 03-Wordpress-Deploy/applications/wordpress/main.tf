resource "aws_instance" "WordpressInstance" {
  count                       = var.total_instances
  ami                         = var.ami_id
  associate_public_ip_address = true
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_public_ids[count.index % length(var.subnet_public_ids)]
  vpc_security_group_ids      = [ aws_security_group.SG-Wordpress.id ]
  user_data                   =  templatefile("${path.module}/deploy.tmpl", {
                                                DBNAME=var.dbname,
                                                DBUSER=var.dbuser,
                                                DBPASS=var.dbpassword,
                                                DBHOST=var.dbhost,
                                                LOCALE=var.wp_locale,
                                                URL=aws_lb.ALB-Wordpress.dns_name,
                                                ADMUSER=var.wp_user_admin,
                                                ADMPASS=var.wp_user_password,
                                                ADMMAIL=var.wp_user_mail,
                                                servername="Wordpress-${count.index}"})
  tags = {
     Name         = "Wordpress-${count.index}"
     Environment  = var.environment
     Team         = var.team
     CostCenter   =  var.costCenter
  }
  iam_instance_profile = aws_iam_instance_profile.ECS-Profile.name

  depends_on = [ aws_iam_role_policy_attachment.RoleMAnagedAttached, aws_lb.ALB-Wordpress ]

}

data "aws_iam_policy_document" "trust-policy-ecs-instance" {
  statement {
    sid = "1"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "ECS-Profile" {
  name = "Wordpress-Instance-Managed-Profile"
  role = aws_iam_role.WordpressRoleManagement.name
}

resource "aws_iam_role" "WordpressRoleManagement" {
  name = "EC2WebServerRoleSSM"
  assume_role_policy = data.aws_iam_policy_document.trust-policy-ecs-instance.json
}
resource "aws_iam_role_policy_attachment" "RoleMAnagedAttached" {
  role       = aws_iam_role.WordpressRoleManagement.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_resourcegroups_group" "WordpressResourceGroup" {
  name = "Wordpress-Resource-Group"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::EC2::Instance"
  ],
  "TagFilters": [
    {
      "Key": "Environment",
      "Values": ["${var.environment}"]
    }
  ]
}
JSON
}
  tags = {
    Name = "Wordpress-Resource-Group"
    Environment = var.environment
    Team         = var.team
    CostCenter   =  var.costCenter

  }
  depends_on = [aws_instance.WordpressInstance]
}

resource "aws_security_group" "SG-Wordpress" {
  name        = "application_wordpress_group"
  description = "Allow inbound traffic for Wordpress ${var.environment} environment"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name         = "application_wordpress_group"
    Environment  = var.environment
    Team         = var.team
    CostCenter   =  var.costCenter
  }

}
