data "aws_ami" "amazon-linux-2" {
 most_recent = true
 owners      = ["amazon"]

 filter {
   name   = "owner-alias"
   values = ["amazon"]
 }


 filter {
   name   = "name"
   values = ["amzn2-ami-hvm*"]
 }
}

resource "aws_instance" "WebServer" {
    count                        = local.total_instances
     ami                         = data.aws_ami.amazon-linux-2.id
     associate_public_ip_address = true
     instance_type               = local.instance_type
     key_name                    = "MacMini"
     subnet_id                   = aws_subnet.public[count.index % length(aws_subnet.public)].id
     vpc_security_group_ids      = [ aws_security_group.SG-WebServer.id ]
     #user_data                   =  file("deploy_frontend.sh")
     user_data                   = <<EOF
#!/bin/bash
sudo sh -c 'echo "Public-Static-WebServer-${count.index}" > /tmp/index.html'
EOF
     tags = {
       Name = "Public-Static-WEBServer-${count.index}"
       Environment = local.env
     }
     iam_instance_profile = aws_iam_instance_profile.ECS-Profile.name

     depends_on = [ aws_iam_role_policy_attachment.RoleMAnagedAttached, aws_subnet.public ]

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
  name = "WebSite-Instance-Profile"
  role = aws_iam_role.WebServerRoleManagement.name
}

resource "aws_iam_role" "WebServerRoleManagement" {
  name = "EC2WebServerRoleSSM"
  assume_role_policy = data.aws_iam_policy_document.trust-policy-ecs-instance.json
}
resource "aws_iam_role_policy_attachment" "RoleMAnagedAttached" {
  role       = aws_iam_role.WebServerRoleManagement.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_resourcegroups_group" "WebServerGroup" {
  name = "WebServer-Group"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::EC2::Instance"
  ],
  "TagFilters": [
    {
      "Key": "Environment",
      "Values": ["${local.env}"]
    }
  ]
}
JSON
}

  depends_on = [aws_instance.WebServer]
}

resource "aws_ssm_document" "WebServerDeploy" {
  name          = "WebServer-Deploy"
  document_type = "Command"
  target_type = "/AWS::EC2::Instance"
  document_format = "YAML"
  content = <<DOC
---
schemaVersion: "2.2"
description: "Command to install HTTP server"
mainSteps:
- action: "aws:runShellScript"
  name: "configWebSerber"
  inputs:
    runCommand:
    - "yum update -y"
    - "yum install httpd -y"
    - "systemctl start httpd"
    - "systemctl enable httpd"
    - "touch /var/www/html/health.html"
    - "mv /tmp/index.html /var/www/html/"
DOC
}

resource "aws_ssm_association" "Deploy" {
  name = aws_ssm_document.WebServerDeploy.name

  targets {
    key    = "InstanceIds"
    values = [
      for inst in aws_instance.WebServer:
        inst.id
    ]
  }

  depends_on = [ aws_instance.WebServer ]
}

resource "aws_security_group" "SG-WebServer" {
  name        = "allow_http"
  description = "Allow HTTP(S) inbound traffic"
  vpc_id      = aws_vpc.principal.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = local.ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name = "allow_http"
  }

}
